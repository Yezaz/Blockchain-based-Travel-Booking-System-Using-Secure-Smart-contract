

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class ContractLinking extends ChangeNotifier {
  final String _rpcURL = "http://192.168.1.36:7545"; // Update with Ganache RPC URL
  final String _wsURL = "ws://192.168.1.36/"; // Update with Ganache WebSocket URL
  final String _privateKey = "0xfe02ac6927a7c5542c2ce158356af46c545a720a8dcb58c3e3cabf1f1eae0528"; // Update with your private key

  late Web3Client _client;
  late String _abiCode;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _setName;
  late ContractFunction _yourName;
  late ContractFunction _getString; // Initialize _getString
  String? storedString; // Define storedString to hold retrieved data
  bool isLoading = false;
  String? deployedName;
  String? error;

  ContractLinking() {
    initialSetup();
  }

  Future<void> initialSetup() async {
    try {
      _client = Web3Client(_rpcURL, http.Client(), socketConnector: () {
        return IOWebSocketChannel.connect(_wsURL).cast<String>();
      });

      await getAbi();
      await getCredentials();
      await getDeployedContract();
    } catch (e) {
      error = "Error initializing Ethereum client: $e";
      print(error);
      notifyListeners();
    }
  }

  Future<void> getAbi() async {
    try {
      String abiStringFile = await rootBundle.loadString("src/artifacts/HelloWorld.json");
      var jsonAbi = jsonDecode(abiStringFile);
      _abiCode = jsonEncode(jsonAbi["abi"]);
      _contractAddress = EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);

      print("Loaded ABI: $_abiCode");
      print("Contract Address: $_contractAddress");
    } catch (e) {
      error = "Error loading ABI: $e";
      print(error);
      notifyListeners();
    }
  }

  Future<void> getDeployedContract() async {
    try {
      _contract = DeployedContract(
          ContractAbi.fromJson(_abiCode, "HelloWorld"), _contractAddress);
      _setName = _contract.function("setName");
      _yourName = _contract.function("yourName");
      _getString = _contract.function("yourName"); // Initialize _getString here

      // Ensure functions are initialized correctly
      if (_setName == null || _yourName == null || _getString == null) {
        throw Exception("Functions not initialized correctly");
      }
    } catch (e) {
      error = "Error deploying contract: $e";
      print(error);
      notifyListeners();
    }
  }


  Future<void> getCredentials() async {
    try {
      _credentials = EthPrivateKey.fromHex(_privateKey);
    } catch (e) {
      error = "Error loading private key: $e";
      print(error);
      notifyListeners();
    }
  }



  Future<void> setName(String nameToSet) async {
    try {
      isLoading = true;
      notifyListeners();

      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _setName,
          parameters: [nameToSet],
        ),
        chainId: 1337,
        fetchChainIdFromNetworkId: false,
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = "Error calling setName function: $e";
      print(error);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getData() async {
    try {
      var result = await _client.call(
        contract: _contract,
        function: _getString,
        params: [],
      );

      storedString = result[0]; // Assign result to storedString, not storedData
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = "Error calling get function: $e";
      print(error);
      notifyListeners();
    }
  }


}


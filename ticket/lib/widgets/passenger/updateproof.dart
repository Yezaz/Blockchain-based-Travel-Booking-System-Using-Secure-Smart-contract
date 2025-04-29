import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddPassengerPage extends StatefulWidget {
  @override
  _AddPassengerPageState createState() => _AddPassengerPageState();
}

class _AddPassengerPageState extends State<AddPassengerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _idNumberController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  File? _idProofFile;
  File? _photoFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  String? currentUserUKey;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final DatabaseReference _passengersRef =
  FirebaseDatabase.instance.ref().child('passengers');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        if (type == 'id') {
          _idProofFile = file;
        } else {
          _photoFile = file;
        }
      });
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          _uploadProgress = taskSnapshot.bytesTransferred.toDouble() /
              taskSnapshot.totalBytes.toDouble();
        });
      });

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  Future<void> _submitPassenger() async {


    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    String? userId = user?.uid;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select date of birth')));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select gender')));
      return;
    }
    if (_idProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload ID proof')));
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    Future<void> _fetchCurrentUserUKey() async {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        setState(() {
          currentUserUKey = userId;
        });
      }
    }


    try {
      // Upload files to Firebase Storage
      final idProofUrl = await _uploadFile(
          _idProofFile!,
          'passenger_documents/${DateTime.now().millisecondsSinceEpoch}_id_proof'
      );

      String? photoUrl;
      if (_photoFile != null) {
        photoUrl = await _uploadFile(
            _photoFile!,
            'passenger_photos/${DateTime.now().millisecondsSinceEpoch}_photo'
        );
      }


      final passengerData = {
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'gender': _selectedGender,
        'ukey': userId,
        'dob': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'idProofUrl': idProofUrl,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'createdAt': ServerValue.timestamp,
      };

      await _passengersRef.child(userId!).set(passengerData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passenger added successfully!'), backgroundColor: Colors.green),
      );

      // Clear form after successful submission
      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = null;
        _selectedGender = null;
        _idProofFile = null;
        _photoFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter name' : null,
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter age' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.transgender),
                        border: OutlineInputBorder(),
                      ),
                      items: _genders.map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select gender' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                        text: _selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                            : ''
                    ),
                    validator: (value) => _selectedDate == null ? 'Please select date' : null,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter phone number' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter address' : null,
              ),
              SizedBox(height: 16),

              // Identification Section
              _buildSectionHeader('Identification'),
              SizedBox(height: 16),

              TextFormField(
                controller: _idNumberController,
                decoration: InputDecoration(
                  labelText: 'ID Number',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter ID number' : null,
              ),
              SizedBox(height: 16),

              // File Upload Section
              _buildFileUploadCard(
                title: 'ID Proof Document',
                file: _idProofFile,
                onTap: () => _pickFile('id'),
                required: true,
              ),
              SizedBox(height: 16),

              _buildFileUploadCard(
                title: 'Passenger Photo (Optional)',
                file: _photoFile,
                onTap: () => _pickFile('photo'),
                required: false,
              ),
              SizedBox(height: 24),

              // Progress Indicator
              if (_uploadProgress > 0 && _uploadProgress < 1)
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),

              SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPassenger,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4285F4),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('SAVE PASSENGER', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4285F4),
      ),
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required File? file,
    required VoidCallback onTap,
    required bool required,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (required)
                  Text(
                    '*Required',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              file != null
                  ? file.path.split('/').last
                  : 'No file selected',
              style: TextStyle(
                  color: file != null ? Colors.green : Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(Icons.upload_file, size: 20),
              label: Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }
}
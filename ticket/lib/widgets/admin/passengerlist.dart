import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PassengerListPage extends StatefulWidget {
  @override
  _PassengerListPageState createState() => _PassengerListPageState();
}

class _PassengerListPageState extends State<PassengerListPage> {
  final DatabaseReference _passengersRef =
  FirebaseDatabase.instance.ref().child('passengers');
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder(
          stream: _passengersRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ));
            }

            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Center(
                  child: Text('No passengers found.',
                      style: TextStyle(fontSize: 18)));
            }

            final data = snapshot.data!.snapshot.value as Map;
            final passengers = data.entries.toList();

            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: passengers.length,
              itemBuilder: (context, index) {
                final passengerKey = passengers[index].key as String;
                final passenger = passengers[index].value as Map;
                final createdAt = passenger['createdAt'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                    int.parse(passenger['createdAt'].toString()))
                    : null;

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showPassengerDetails(context, passengerKey, passenger);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Passenger Photo
                          Hero(
                            tag: 'passenger-image-${passengerKey}',
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: passenger['photoUrl'] != null
                                    ? CachedNetworkImage(
                                  imageUrl: passenger['photoUrl'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Center(
                                          child:
                                          CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person,
                                          size: 40,
                                          color: Colors.grey),
                                )
                                    : Icon(Icons.person,
                                    size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Passenger Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passenger['name'] ?? 'No name',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ID: ${passenger['idNumber'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Phone: ${passenger['phone'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (createdAt != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Registered: ${_dateFormat.format(createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Colors.blue.shade400),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showPassengerDetails(
      BuildContext context, String passengerKey, Map passenger) {
    final dob = passenger['dob'] != null
        ? DateTime.parse(passenger['dob'].toString())
        : null;
    final createdAt = passenger['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
        int.parse(passenger['createdAt'].toString()))
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: 'passenger-image-$passengerKey',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: passenger['photoUrl'] != null
                        ? CachedNetworkImage(
                      imageUrl: passenger['photoUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                        : Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                passenger['name'] ?? 'No name',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                passenger['idNumber'] ?? 'ID: N/A',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 24),
            _buildDetailRow(Icons.phone, 'Phone', passenger['phone'] ?? 'N/A'),
            _buildDetailRow(
                Icons.credit_card, 'ID Proof', passenger['idNumber'] ?? 'N/A'),
            _buildDetailRow(Icons.cake, 'Date of Birth',
                dob != null ? _dateFormat.format(dob) : 'N/A'),
            _buildDetailRow(Icons.person, 'Gender', passenger['gender'] ?? 'N/A'),
            _buildDetailRow(
                Icons.location_on, 'Address', passenger['address'] ?? 'N/A'),
            _buildDetailRow(Icons.calendar_today, 'Age', passenger['age'] ?? 'N/A'),
            if (passenger['idProofUrl'] != null) ...[
              SizedBox(height: 16),
              Text(
                'ID Proof Document:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: passenger['idProofUrl'],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                        child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          Text('Failed to load document'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),
            if (createdAt != null)
              Text(
                'Registered on: ${_dateFormat.format(createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue.shade600),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
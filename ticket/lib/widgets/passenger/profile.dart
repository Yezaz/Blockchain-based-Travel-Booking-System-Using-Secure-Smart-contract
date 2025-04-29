import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('passengers');
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final DataSnapshot snapshot = await _dbRef.get();
    final data = snapshot.value as Map<dynamic, dynamic>;

    for (var entry in data.entries) {
      final passenger = Map<String, dynamic>.from(entry.value);
      if (passenger['ukey'] == user.uid) {
        setState(() {
          profileData = passenger;
          isLoading = false;
        });
        return;
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : profileData == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 20),
            Text(
              "Profile not found",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileData!['photoUrl'] != null
                          ? CachedNetworkImageProvider(profileData!['photoUrl'])
                          : null,
                      child: profileData!['photoUrl'] == null
                          ? Icon(Icons.person, size: 60, color: Colors.blue)
                          : null,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    profileData!['name'] ?? 'No Name',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    profileData!['phone'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Personal Information Card
            Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                        height: 20,
                      ),
                      _buildProfileRow(Icons.cake_outlined, 'Age', profileData!['age']),
                      _buildProfileRow(Icons.calendar_today, 'DOB', profileData!['dob']),
                      _buildProfileRow(Icons.transgender, 'Gender', profileData!['gender']),
                      _buildProfileRow(Icons.phone, 'Phone', profileData!['phone']),
                      _buildProfileRow(Icons.home, 'Address', profileData!['address']),
                    ],
                  ),
                ),
              ),
            ),

            // ID Information Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            'ID Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                        height: 20,
                      ),
                      _buildProfileRow(Icons.badge, 'ID Number', profileData!['idNumber']),
                      SizedBox(height: 15),
                      Text(
                        'ID Proof Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: profileData!['idProofUrl'] != null
                              ? CachedNetworkImage(
                            imageUrl: profileData!['idProofUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 40, color: Colors.red),
                                  SizedBox(height: 10),
                                  Text('Failed to load image'),
                                ],
                              ),
                            ),
                          )
                              : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 10),
                                Text('No ID proof available'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }


  Widget _buildProfileRow(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blue[700]),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value ?? 'Not provided',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
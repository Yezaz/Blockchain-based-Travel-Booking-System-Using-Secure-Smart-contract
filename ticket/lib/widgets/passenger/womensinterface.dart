import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:womenss/widgets/passenger/profile.dart';
import 'package:womenss/widgets/passenger/updateproof.dart';

import 'LoginPage.dart';
import 'book.dart';
import 'myticket.dart';

class BusHomePage extends StatefulWidget {
  const BusHomePage({Key? key}) : super(key: key);

  @override
  _BusHomePageState createState() => _BusHomePageState();
}

class _BusHomePageState extends State<BusHomePage> {
  bool _isLogoutLoading = false;
  int _currentIndex = 0;
  late List<Widget> _pages;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _pages = [
      AddPassengerPage(),
      LongTravelBookingPage(),
      ProfilePage(),
    ];
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
      final snapshot = await userRef.once();

      if (snapshot.snapshot.value != null) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found')),
        );
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLogoutLoading = true);
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BusLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.directions_bus, size: 28),
            SizedBox(width: 10),
            Text('SwiftTransit'),
          ],
        ),
        backgroundColor: Colors.blue,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {

              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyTickets())
              );



            },
          ),
          IconButton(
            icon: _isLogoutLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'My Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),

    );
  }
}

class HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Your Journey',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildSearchCard(),
          SizedBox(height: 25),
          Text(
            'Popular Routes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          _buildPopularRoutes(),
          SizedBox(height: 25),
          Text(
            'Special Offers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          _buildSpecialOffers(),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'From',
                prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'To',
                prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Search action
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.deepPurple,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Search Buses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRoutes() {
    final routes = [
      {'from': 'New York', 'to': 'Boston', 'price': '\$25'},
      {'from': 'Los Angeles', 'to': 'San Francisco', 'price': '\$35'},
      {'from': 'Chicago', 'to': 'Detroit', 'price': '\$20'},
    ];

    return Column(
      children: routes.map((route) {
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(Icons.directions_bus, color: Colors.deepPurple),
            title: Text('${route['from']} to ${route['to']}'),
            subtitle: Text('From ${route['price']}'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Route selection action
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialOffers() {
    return Container(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildOfferCard('20% OFF', 'First time users', Icons.card_giftcard),
          _buildOfferCard('15% OFF', 'Weekend special', Icons.weekend),
          _buildOfferCard('10% OFF', 'Group booking', Icons.group),
        ],
      ),
    );
  }

  Widget _buildOfferCard(String title, String subtitle, IconData icon) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 10),
      child: Card(
        color: Colors.deepPurple[50],
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.deepPurple),
              SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}



void main() {
  runApp(MaterialApp(
    title: 'Bus Ticket Booking',
    theme: ThemeData(
      primarySwatch: Colors.deepPurple,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: BusHomePage(),
  ));
}
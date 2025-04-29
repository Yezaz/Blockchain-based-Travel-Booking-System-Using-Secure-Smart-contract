import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:womenss/widgets/admin/passengerlist.dart';
import 'package:womenss/widgets/admin/ticketlist.dart';
import 'package:womenss/widgets/admin/viewticket.dart';


import 'Loginn.dart';



class AdminDashboard extends StatefulWidget {
  final String? email;
  final String? uid;

  const AdminDashboard({
    Key? key,
    this.email,
    this.uid,
  }) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = false;
  int _currentIndex = 0;

  final List<Widget> _pages = [
    AdminBusTicketViewPage(),
    PassengerListPage(),
    TicketsPage(),

  ];

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Color(0xFF1976D2),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Administrator"),
              accountEmail: Text(widget.email ?? "admin@example.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: Color(0xFF1976D2)),
              ),
              decoration: BoxDecoration(
                color: Color(0xFF1976D2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Color(0xFF1976D2)),
              title: Text('Dashboard'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: Color(0xFF1976D2)),
              title: Text('Passengers List'),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.content_paste, color: Color(0xFF1976D2)),
              title: Text('Tickets Details'),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),

          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Passengers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_paste),
            label: 'Tickets',
          ),

        ],
      ),
    );
  }
}

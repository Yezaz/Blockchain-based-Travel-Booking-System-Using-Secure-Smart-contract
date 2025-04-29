import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:womenss/widgets/passenger/womensinterface.dart';

class MyTickets extends StatefulWidget {
  @override
  _MyTicketsState createState() => _MyTicketsState();
}

class _MyTicketsState extends State<MyTickets> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('bookings');
  List<Map<dynamic, dynamic>> _userBookings = [];
  bool _loading = true;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _fetchUserBookings();
  }

  Future<void> _fetchUserBookings() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    _dbRef.once().then((DatabaseEvent event) {
      final dataSnapshot = event.snapshot;
      List<Map<dynamic, dynamic>> tempBookings = [];

      if (dataSnapshot.value != null) {
        final bookings = Map<String, dynamic>.from(dataSnapshot.value as Map);

        bookings.forEach((key, value) {
          final booking = Map<String, dynamic>.from(value);
          if (booking['ukey'] == currentUser.uid) {
            booking['bookingId'] = key; // Store booking ID for reference
            tempBookings.add(booking);
          }
        });

        // Sort by date (newest first)
        tempBookings.sort((a, b) {
          final aDate = a['timestamp'] ?? 0;
          final bDate = b['timestamp'] ?? 0;
          return bDate.compareTo(aDate);
        });
      }

      setState(() {
        _userBookings = tempBookings;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BusHomePage())
        );
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('My Tickets', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchUserBookings,
            ),
          ],
        ),
        body: _loading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        )
            : _userBookings.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.airplane_ticket, size: 60, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'No Bookings Found',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'You haven\'t booked any tickets yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUserBookings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Refresh', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchUserBookings,
          color: Colors.blue,
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: _userBookings.length,
            itemBuilder: (context, index) {
              final booking = _userBookings[index];
              final travelDate = booking['date'] != null
                  ? DateTime.parse(booking['date'].toString())
                  : DateTime.now();
              final bookingDate = booking['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(booking['timestamp'].toString()))
                  : DateTime.now();
              final status = booking['status']?.toString().toLowerCase() ?? 'pending';

              return _buildTicketCard(booking, travelDate, bookingDate, status);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(
      Map booking, DateTime travelDate, DateTime bookingDate, String status) {
    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetails(booking, travelDate, bookingDate, statusColor),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${booking['source']} → ${booking['destination']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Text(
                    '${_dateFormat.format(travelDate)} at ${_timeFormat.format(travelDate)}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 20, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Text(
                    booking['name'] ?? 'No name',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.confirmation_number, size: 20, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Text(
                    'Booking ID: ${booking['bookingId']?.substring(0, 8) ?? 'N/A'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (booking['seat'] != null)
                Row(
                  children: [
                    Icon(Icons.event_seat, size: 20, color: Colors.blue.shade600),
                    SizedBox(width: 8),
                    Text(
                      'Seat: ${booking['seat']}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(
      Map booking, DateTime travelDate, DateTime bookingDate, Color statusColor) {
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Center(
              child: Text(
                'Ticket Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildDetailItem('Route', '${booking['source']} → ${booking['destination']}'),
            _buildDetailItem('Travel Date', '${_dateFormat.format(travelDate)} at ${_timeFormat.format(travelDate)}'),
            _buildDetailItem('Passenger Name', booking['name']),
            _buildDetailItem('Phone Number', booking['phone']),
            _buildDetailItem('ID Proof', booking['idProof']),
            _buildDetailItem('Booking ID', booking['bookingId']),
            _buildDetailItem('Booked On', '${_dateFormat.format(bookingDate)} at ${_timeFormat.format(bookingDate)}'),
            _buildDetailItem('Status', booking['status']?.toString().toUpperCase() ?? 'PENDING',
                statusColor: statusColor),
            if (booking['seat'] != null)
              _buildDetailItem('Seat Number', booking['seat']),
            if (booking['bus'] != null)
              _buildDetailItem('Bus', booking['bus']),
            if (booking['fare'] != null)
              _buildDetailItem('Fare', '\$${booking['fare']}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.blue,
              ),
              child: Text('Close', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value, {Color? statusColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value ?? 'Not available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: statusColor ?? Colors.black,
            ),
          ),
          Divider(height: 20),
        ],
      ),
    );
  }
}
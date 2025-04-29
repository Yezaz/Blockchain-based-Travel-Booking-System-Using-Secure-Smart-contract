import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';

class BusTicketViewPage extends StatelessWidget {
  const BusTicketViewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('bookings');

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Bus Tickets'),
      ),
      body: FirebaseAnimatedList(
        query: databaseRef,
        itemBuilder: (context, snapshot, animation, index) {
          final bookingData = snapshot.value as Map<dynamic, dynamic>;
          final travelDate = DateTime.parse(bookingData['date']);
          final bookingId = snapshot.key!;

          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text('${bookingData['source']} to ${bookingData['destination']}'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(travelDate)),
              trailing: Chip(
                label: Text(bookingData['status']),
                backgroundColor: bookingData['status'] == 'confirmed'
                    ? Colors.green[100]
                    : Colors.orange[100],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusTicketDetailsPage(bookingId: bookingId),
                  ),
                );
              },
            ),
          );
        },
        defaultChild: Center(child: CircularProgressIndicator()),

      ),
    );
  }
}

class BusTicketDetailsPage extends StatelessWidget {
  final String bookingId;

  const BusTicketDetailsPage({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('bookings').child(bookingId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Printing ticket...')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing ticket...')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('Booking not found'));
          }

          final bookingData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final bookingDate = DateTime.fromMillisecondsSinceEpoch(bookingData['timestamp']);
          final travelDate = DateTime.parse(bookingData['date']);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTicketHeader(bookingData['status']),
                SizedBox(height: 16),
                _buildTicketCard(bookingData, bookingDate, travelDate),
                SizedBox(height: 24),
                _buildActionButton(context, bookingData['status'], bookingId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketHeader(String status) {
    return Column(
      children: [
        Text(
          'BusTicket Pro',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: status == 'confirmed' ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: status == 'confirmed' ? Colors.green : Colors.orange),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: status == 'confirmed' ? Colors.green[800] : Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(
      Map<dynamic, dynamic> bookingData, DateTime bookingDate, DateTime travelDate) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRouteSection(bookingData['source'], bookingData['destination'], travelDate),
            Divider(thickness: 2),
            _buildPassengerSection(bookingData['name'], bookingData['idProof'], bookingData['phone']),
            Divider(thickness: 2),
            _buildBookingDetailsSection(bookingDate, bookingData),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection(String source, String destination, DateTime travelDate) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEPARTURE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEE, MMM dd, yyyy').format(travelDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward, size: 30, color: Colors.blue),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  destination,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Estimated Duration: 8 hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDetailChip(
              icon: Icons.directions_bus,
              label: 'Deluxe AC',
            ),
            _buildDetailChip(
              icon: Icons.confirmation_number,
              label: 'Seat 12A',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPassengerSection(String name, String idProof, String phone) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASSENGER DETAILS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'ID Verified',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.person, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.credit_card, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'ID: $idProof',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.phone, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              phone,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingDetailsSection(DateTime bookingDate, Map<dynamic, dynamic> bookingData) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BOOKING DETAILS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Fare: \$45.00',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Table(
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          children: [
            _buildTableRow('Booking Date',
                DateFormat('MMM dd, yyyy - hh:mm a').format(bookingDate)),
            _buildTableRow('Bus Operator', 'City Travels'),
            _buildTableRow('Bus Number', 'TN 72 AB 1234'),
            _buildTableRow('Boarding Point', '${bookingData['source']} Central'),
            _buildTableRow('Drop Point', '${bookingData['destination']} Main Stand'),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.blue),
      label: Text(label),
      backgroundColor: Colors.blue[50],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String status, String bookingId) {
    if (status == 'pending') {
      return ElevatedButton(
        onPressed: () => _showCancelDialog(context, bookingId),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('CANCEL BOOKING', style: TextStyle(fontSize: 16)),
      );
    } else {
      return Text(
        'This booking cannot be modified',
        style: TextStyle(color: Colors.grey),
      );
    }
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseDatabase.instance
                    .ref()
                    .child('bookings')
                    .child(bookingId)
                    .update({'status': 'cancelled'});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking cancelled successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to cancel booking')),
                );
              }
            },
            child: Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
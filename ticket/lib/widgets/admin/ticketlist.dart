import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('bookings');
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading data',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.airplane_ticket, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text('No bookings found',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final bookingsMap = snapshot.data!.snapshot.value as Map;
          final bookingsList = bookingsMap.entries.toList();

          // Sort by date (newest first)
          bookingsList.sort((a, b) {
            final aDate = (a.value as Map)['timestamp'] ?? 0;
            final bDate = (b.value as Map)['timestamp'] ?? 0;
            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: bookingsList.length,
            itemBuilder: (context, index) {
              final bookingKey = bookingsList[index].key as String;
              final booking = bookingsList[index].value as Map;
              final dateTime = booking['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(booking['timestamp'].toString()))
                  : DateTime.now();
              final status = booking['status']?.toString().toLowerCase() ?? 'pending';

              return _buildTicketCard(context, bookingKey, booking, dateTime, status);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(
      BuildContext context, String bookingKey, Map booking, DateTime dateTime, String status) {
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetails(context, bookingKey, booking, dateTime),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${booking['source']} → ${booking['destination']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    booking['name'] ?? 'No name',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    _dateFormat.format(dateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    booking['phone'] ?? 'No phone',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (booking['idProof'] != null)
                Row(
                  children: [
                    Icon(Icons.credit_card, size: 20, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      booking['idProof']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, String bookingKey, Map booking, DateTime dateTime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailItem('Booking ID', bookingKey),
            _buildDetailItem('Passenger Name', booking['name']),
            _buildDetailItem('Phone Number', booking['phone']),
            _buildDetailItem('ID Proof', booking['idProof']),
            _buildDetailItem('Route', '${booking['source']} → ${booking['destination']}'),
            _buildDetailItem('Travel Date', booking['date']),
            _buildDetailItem('Booking Time', _dateFormat.format(dateTime)),
            _buildDetailItem('Status', booking['status']?.toString().toUpperCase() ?? 'PENDING'),
            if (booking['fare'] != null) _buildDetailItem('Fare', '\$${booking['fare']}'),
            if (booking['seat'] != null) _buildDetailItem('Seat Number', booking['seat']),
            if (booking['bus'] != null) _buildDetailItem('Bus', booking['bus']),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Close'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(height: 4),
          Text(
            value ?? 'Not available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}
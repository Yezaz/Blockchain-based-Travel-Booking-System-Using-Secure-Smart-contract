/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Ticket Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdminBusTicketViewPage(),
    );
  }
}

class AdminBusTicketViewPage extends StatelessWidget {
  const AdminBusTicketViewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('bookings');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Bus Ticket Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context, databaseRef),
          ),
        ],
      ),
      body: FirebaseAnimatedList(
        query: databaseRef,
        sort: (a, b) => b.child('timestamp').value.toString().compareTo(
          a.child('timestamp').value.toString(),
        ),
        itemBuilder: (context, snapshot, animation, index) {
          final bookingData = snapshot.value as Map<dynamic, dynamic>? ?? {};
          final travelDate = bookingData['date'] != null
              ? DateTime.parse(bookingData['date'].toString())
              : DateTime.now();
          final bookingId = snapshot.key ?? 'N/A';
          final passengerId = bookingData['passengerId']?.toString() ?? 'N/A';

          return Card(
            margin: const EdgeInsets.all(8),
            elevation: 2,
            child: ListTile(
              title: Text('${bookingData['source'] ?? 'N/A'} to ${bookingData['destination'] ?? 'N/A'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM dd, yyyy').format(travelDate)),
                  const SizedBox(height: 4),
                  Text('Passenger: ${bookingData['name'] ?? 'N/A'}'),
                ],
              ),
              trailing: _buildTrailingIcons(context, bookingData, bookingId, passengerId),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminBusTicketDetailsPage(
                      bookingId: bookingId,
                      passengerId: passengerId,
                    ),
                  ),
                );
              },
            ),
          );
        },
        defaultChild: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildTrailingIcons(BuildContext context, Map<dynamic, dynamic> bookingData, String bookingId, String passengerId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bookingData['status'] != null)
          _buildStatusChip(bookingData['status']!.toString())
        else
          _buildStatusChip('pending'),

        const SizedBox(width: 4),

        IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: passengerId != 'N/A'
              ? () => _viewPassengerProofs(context, passengerId)
              : null,
          tooltip: passengerId != 'N/A' ? 'View passenger proofs' : 'No passenger ID available',
        ),

        const SizedBox(width: 4),

        IconButton(
          icon: const Icon(Icons.remove_red_eye),
          onPressed: bookingId != 'N/A'
              ? () => _navigateToTicketViewPage(context, bookingId, passengerId)
              : null,
          tooltip: bookingId != 'N/A' ? 'View ticket details' : 'No booking ID available',
        ),
      ],
    );
  }

  void _navigateToTicketViewPage(BuildContext context, String bookingId, String passengerId) {
    if (bookingId == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking ID not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketViewPage(
          bookingId: bookingId,
          passengerId: passengerId,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        break;
      default:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 12, color: textColor),
      ),
      backgroundColor: backgroundColor,
    );
  }

  Future<void> _viewPassengerProofs(BuildContext context, String passengerId) async {
    if (passengerId == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger ID not available')),
      );
      return;
    }

    final passengerRef = FirebaseDatabase.instance.ref().child('passengers').child(passengerId);
    final snapshot = await passengerRef.get();

    if (!snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger data not found')),
      );
      return;
    }

    final passengerData = snapshot.value as Map<dynamic, dynamic>? ?? {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerProofsPage(
          passengerName: passengerData['name']?.toString() ?? 'N/A',
          idProofUrl: passengerData['idProofUrl']?.toString() ?? '',
          photoUrl: passengerData['photoUrl']?.toString() ?? '',
        ),
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context, DatabaseReference ref) async {
    String selectedStatus = 'all';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('All Bookings'),
                  value: 'all',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Pending'),
                  value: 'pending',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Confirmed'),
                  value: 'confirmed',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Rejected'),
                  value: 'rejected',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Filter applied: $selectedStatus')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class TicketViewPage extends StatelessWidget {
  final String bookingId;
  final String passengerId;

  const TicketViewPage({
    Key? key,
    required this.bookingId,
    required this.passengerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('bookings').child(bookingId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Ticket not found'));
          }

          final bookingData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
          final travelDate = bookingData['date'] != null
              ? DateTime.parse(bookingData['date'].toString())
              : DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'BUS TICKET',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FROM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  bookingData['source']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward, color: Colors.blue),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'TO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  bookingData['destination']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DATE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(travelDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'TIME',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  bookingData['time']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(3),
                          },
                          children: [
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Passenger:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    bookingData['name']?.toString() ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Seat:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    bookingData['seat']?.toString() ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Bus:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    bookingData['bus']?.toString() ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Fare:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '\$${bookingData['fare']?.toString() ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Booking ID:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    bookingId,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to List'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class AdminBusTicketDetailsPage extends StatelessWidget {
  final String bookingId;
  final String passengerId;

  const AdminBusTicketDetailsPage({
    Key? key,
    required this.bookingId,
    required this.passengerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('bookings').child(bookingId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => _viewPassengerProofs(context, passengerId),
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Booking not found'));
          }

          final bookingData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
          final bookingDate = bookingData['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(int.parse(bookingData['timestamp'].toString()))
              : DateTime.now();
          final travelDate = bookingData['date'] != null
              ? DateTime.parse(bookingData['date'].toString())
              : DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAdminTicketHeader(bookingData['status']?.toString() ?? 'pending'),
                const SizedBox(height: 16),
                _buildTicketCard(bookingData, bookingDate, travelDate),
                const SizedBox(height: 24),
                if ((bookingData['status']?.toString() ?? '').toLowerCase() == 'pending')
                  _buildAdminActionButtons(context, bookingId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminTicketHeader(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Column(
      children: [
        const Text(
          'ADMIN VIEW',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRouteSection(
                bookingData['source']?.toString() ?? 'N/A',
                bookingData['destination']?.toString() ?? 'N/A',
                travelDate),
            const Divider(thickness: 2),
            _buildPassengerSection(
                bookingData['name']?.toString() ?? 'N/A',
                bookingData['idProof']?.toString() ?? 'N/A',
                bookingData['phone']?.toString() ?? 'N/A'),
            const Divider(thickness: 2),
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
                const Text(
                  'DEPARTURE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  source,
                  style: const TextStyle(
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
            const Icon(Icons.arrow_forward, size: 30, color: Colors.blue),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Estimated Duration: 8 hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),

      ],
    );
  }

  Widget _buildPassengerSection(String name, String idProof, String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PASSENGER DETAILS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.person, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.credit_card, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'ID: $idProof',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.phone, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              phone,
              style: const TextStyle(fontSize: 14),
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
            const Text(
              'BOOKING DETAILS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          children: [
            _buildTableRow('Booking Date',
                DateFormat('MMM dd, yyyy - hh:mm a').format(bookingDate)),
            _buildTableRow('Bus Operator', 'City Travels'),
            _buildTableRow('Bus Number', 'TN 72 AB 1234'),
            _buildTableRow('Boarding Point', '${bookingData['source'] ?? 'N/A'} Central'),
            _buildTableRow('Drop Point', '${bookingData['destination'] ?? 'N/A'} Main Stand'),
            _buildTableRow('Booking ID', bookingId),
            _buildTableRow('Passenger ID', passengerId),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blueAccent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActionButtons(BuildContext context, String bookingId) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateBookingStatus(context, bookingId, 'rejected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('REJECT', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateBookingStatus(context, bookingId, 'confirmed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('CONFIRM', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Future<void> _updateBookingStatus(
      BuildContext context, String bookingId, String status) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('bookings')
          .child(bookingId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $status successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking status')),
      );
    }
  }

  Future<void> _viewPassengerProofs(BuildContext context, String passengerId) async {
    if (passengerId == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger ID not available')),
      );
      return;
    }

    final passengerRef = FirebaseDatabase.instance.ref().child('passengers').child(passengerId);
    final snapshot = await passengerRef.get();

    if (!snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger data not found')),
      );
      return;
    }

    final passengerData = snapshot.value as Map<dynamic, dynamic>? ?? {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerProofsPage(
          passengerName: passengerData['name']?.toString() ?? 'N/A',
          idProofUrl: passengerData['idProofUrl']?.toString() ?? '',
          photoUrl: passengerData['photoUrl']?.toString() ?? '',
        ),
      ),
    );
  }
}

class PassengerProofsPage extends StatelessWidget {
  final String passengerName;
  final String idProofUrl;
  final String photoUrl;

  const PassengerProofsPage({
    Key? key,
    required this.passengerName,
    required this.idProofUrl,
    required this.photoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Passenger Proofs - $passengerName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Passenger Photo',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
                  : const Center(child: Text('No photo available')),
            ),
            const SizedBox(height: 24),
            Text(
              'ID Proof Document',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: idProofUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: idProofUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
                  : const Center(child: Text('No ID proof available')),
            ),
          ],
        ),
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Ticket Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdminBusTicketViewPage(),
    );
  }
}

class AdminBusTicketViewPage extends StatelessWidget {
  const AdminBusTicketViewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('bookings');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Bus Ticket Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context, databaseRef),
          ),
        ],
      ),
      body: FirebaseAnimatedList(
        query: databaseRef,
        sort: (a, b) => b.child('timestamp').value.toString().compareTo(
          a.child('timestamp').value.toString(),
        ),
        itemBuilder: (context, snapshot, animation, index) {
          final bookingData = snapshot.value as Map<dynamic, dynamic>? ?? {};
          final travelDate = bookingData['date'] != null
              ? DateTime.parse(bookingData['date'].toString())
              : DateTime.now();
          final bookingId = snapshot.key ?? 'N/A';
          final passengerId = bookingData['ukey']?.toString() ?? 'N/A';

          return Card(
            margin: const EdgeInsets.all(8),
            elevation: 2,
            child: ListTile(
              title: Text(
                  '${bookingData['source'] ?? 'N/A'} to ${bookingData['destination'] ?? 'N/A'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM dd, yyyy').format(travelDate)),
                  const SizedBox(height: 4),
                  Text('Passenger: ${bookingData['name'] ?? 'N/A'}'),
                ],
              ),
              trailing: _buildTrailingIcons(context, bookingData, bookingId, passengerId),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminBusTicketDetailsPage(
                      bookingId: bookingId,
                      passengerId: passengerId,
                    ),
                  ),
                );
              },
            ),
          );
        },
        defaultChild: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildTrailingIcons(BuildContext context, Map<dynamic, dynamic> bookingData,
      String bookingId, String passengerId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bookingData['status'] != null)
          _buildStatusChip(bookingData['status']!.toString())
        else
          _buildStatusChip('pending'),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          onPressed: () {
            if (passengerId != 'N/A') {
              _viewPassengerProofs(context, passengerId);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No passenger ID available')),
              );
            }
          },
          tooltip: 'View passenger proofs',
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        break;
      default:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 12, color: textColor),
      ),
      backgroundColor: backgroundColor,
    );
  }

  Future<void> _viewPassengerProofs(BuildContext context, String passengerId) async {
    try {
      final passengerRef = FirebaseDatabase.instance.ref().child('passengers').child(passengerId);
      final snapshot = await passengerRef.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger data not found')),
        );
        return;
      }

      final passengerData = snapshot.value as Map<dynamic, dynamic>? ?? {};

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PassengerProofsPage(
            passengerName: passengerData['name']?.toString() ?? 'N/A',
            idProofUrl: passengerData['idProofUrl']?.toString() ?? '',
            photoUrl: passengerData['photoUrl']?.toString() ?? '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading passenger data')),
      );
    }
  }

  Future<void> _showFilterDialog(BuildContext context, DatabaseReference ref) async {
    String selectedStatus = 'all';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('All Bookings'),
                  value: 'all',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Pending'),
                  value: 'pending',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Confirmed'),
                  value: 'confirmed',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Rejected'),
                  value: 'rejected',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Filter applied: $selectedStatus')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class AdminBusTicketDetailsPage extends StatelessWidget {
  final String bookingId;
  final String passengerId;

  const AdminBusTicketDetailsPage({
    Key? key,
    required this.bookingId,
    required this.passengerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref().child('bookings').child(bookingId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              if (passengerId != 'N/A') {
                _viewPassengerProofs(context, passengerId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No passenger ID available')),
                );
              }
            },
            tooltip: 'View passenger proofs',
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Booking not found'));
          }

          final bookingData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
          final bookingDate = bookingData['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(bookingData['timestamp'].toString()))
              : DateTime.now();
          final travelDate = bookingData['date'] != null
              ? DateTime.parse(bookingData['date'].toString())
              : DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAdminTicketHeader(bookingData['status']?.toString() ?? 'pending'),
                const SizedBox(height: 16),
                _buildTicketCard(bookingData, bookingDate, travelDate),
                const SizedBox(height: 24),
                if ((bookingData['status']?.toString() ?? '').toLowerCase() == 'pending')
                  _buildAdminActionButtons(context, bookingId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminTicketHeader(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Column(
      children: [
        const Text(
          'ADMIN VIEW',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRouteSection(
                bookingData['source']?.toString() ?? 'N/A',
                bookingData['destination']?.toString() ?? 'N/A',
                travelDate),
            const Divider(thickness: 2),
            _buildPassengerSection(
                bookingData['name']?.toString() ?? 'N/A',
                bookingData['idProof']?.toString() ?? 'N/A',
                bookingData['phone']?.toString() ?? 'N/A'),
            const Divider(thickness: 2),
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
                const Text(
                  'DEPARTURE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  source,
                  style: const TextStyle(
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
            const Icon(Icons.arrow_forward, size: 30, color: Colors.blue),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Estimated Duration: 8 hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPassengerSection(String name, String idProof, String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PASSENGER DETAILS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.person, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.credit_card, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'ID: $idProof',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.phone, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              phone,
              style: const TextStyle(fontSize: 14),
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
            const Text(
              'BOOKING DETAILS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          children: [
            _buildTableRow('Booking Date',
                DateFormat('MMM dd, yyyy - hh:mm a').format(bookingDate)),
            _buildTableRow('Bus Operator', 'City Travels'),
            _buildTableRow('Bus Number', 'TN 72 AB 1234'),
            _buildTableRow('Boarding Point', '${bookingData['source'] ?? 'N/A'} Central'),
            _buildTableRow('Drop Point', '${bookingData['destination'] ?? 'N/A'} Main Stand'),
            _buildTableRow('Booking ID', bookingId),
            _buildTableRow('Passenger ID', passengerId),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActionButtons(BuildContext context, String bookingId) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateBookingStatus(context, bookingId, 'rejected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('REJECT', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateBookingStatus(context, bookingId, 'confirmed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('CONFIRM', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Future<void> _updateBookingStatus(
      BuildContext context, String bookingId, String status) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('bookings')
          .child(bookingId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $status successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking status')),
      );
    }
  }

  Future<void> _viewPassengerProofs(BuildContext context, String passengerId) async {
    try {
      final passengerRef = FirebaseDatabase.instance.ref().child('passengers').child(passengerId);
      final snapshot = await passengerRef.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger data not found')),
        );
        return;
      }

      final passengerData = snapshot.value as Map<dynamic, dynamic>? ?? {};

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PassengerProofsPage(
            passengerName: passengerData['name']?.toString() ?? 'N/A',
            idProofUrl: passengerData['idProofUrl']?.toString() ?? '',
            photoUrl: passengerData['photoUrl']?.toString() ?? '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading passenger data')),
      );
    }
  }
}

class PassengerProofsPage extends StatelessWidget {
  final String passengerName;
  final String idProofUrl;
  final String photoUrl;

  const PassengerProofsPage({
    Key? key,
    required this.passengerName,
    required this.idProofUrl,
    required this.photoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Passenger Proofs - $passengerName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Passenger Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
                  : const Center(child: Text('No photo available')),
            ),
            const SizedBox(height: 24),
            const Text(
              'ID Proof Document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: idProofUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: idProofUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
                  : const Center(child: Text('No ID proof available')),
            ),
          ],
        ),
      ),
    );
  }
}
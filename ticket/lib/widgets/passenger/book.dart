import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/animation.dart';

class LongTravelBookingPage extends StatefulWidget {
  @override
  _LongTravelBookingPageState createState() => _LongTravelBookingPageState();
}

class _LongTravelBookingPageState extends State<LongTravelBookingPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _idProofController = TextEditingController();

  DateTime? _selectedDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('bookings');
  bool _isSubmitting = false;

  String? currentUserUKey;


  @override
  void initState() {
    super.initState();

    _fetchCurrentUserUKey();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0, 0.5, curve: Curves.easeIn),
        ) // <== This closing parenthesis was missing
    );


    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _fetchCurrentUserUKey() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        currentUserUKey = userId;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        // Create booking data map
        final bookingData = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'source': _sourceController.text,
          'destination': _destinationController.text,
          'idProof': _idProofController.text,
          'date': _selectedDate?.toIso8601String(),
          'timestamp': ServerValue.timestamp,
          'status': 'pending',
          'ukey': currentUserUKey,
        };

        // Push data to Firebase
        final newBookingRef = _databaseRef.push();
        await newBookingRef.set(bookingData);

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AnimatedDialog(
            child: BookingConfirmationDialog(
              bookingId: newBookingRef.key,
              name: _nameController.text,
              source: _sourceController.text,
              destination: _destinationController.text,
              date: _selectedDate,
            ),
          ),
        );

        // Clear form after successful submission
        _formKey.currentState?.reset();
        setState(() => _selectedDate = null);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting booking: ${e.toString()}')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }



  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF64B5F6), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Column(
                            children: [
                              _buildHeader(),
                              SizedBox(height: 30),
                              _buildBookingCard(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [

        SizedBox(height: 15),
        Text(
          'Book Your Long Journey',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black26,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Start your adventure with us',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }


  Widget _buildBookingCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 12,
      shadowColor: Colors.blue.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white, Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextFieldWithIcon(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                ),
                _buildTextFieldWithIcon(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  inputType: TextInputType.phone,
                ),
                _buildDatePicker(),
                _buildTextFieldWithIcon(
                  controller: _sourceController,
                  label: 'Source',
                  icon: Icons.place,
                ),
                _buildTextFieldWithIcon(
                  controller: _destinationController,
                  label: 'Destination',
                  icon: Icons.place,
                ),
                _buildTextFieldWithIcon(
                  controller: _idProofController,
                  label: 'ID Proof Number',
                  icon: Icons.credit_card,
                ),
                SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Travel Date',
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blueAccent),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
          ),
          child: Row(
            children: [
              Text(
                _selectedDate != null
                    ? DateFormat('EEE, MMM d, y').format(_selectedDate!)
                    : 'Select a date',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
              Spacer(),
              if (_selectedDate != null)
                Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          primary: Colors.blueAccent,
          onPrimary: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, size: 20),
            SizedBox(width: 10),
            Text(
              'CONFIRM BOOKING',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedDialog extends StatelessWidget {
  final Widget child;

  const AnimatedDialog({required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.elasticOut,
        ),
        child: child,
      ),
    );
  }
}

class BookingConfirmationDialog extends StatelessWidget {
  final String name;
  final String destination;
  final String? bookingId;
  final String source;
  final DateTime? date;

  const BookingConfirmationDialog({
    required this.name,
    required this.destination,
    required this.bookingId,
    required this.source,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 60, color: Colors.green),
          SizedBox(height: 20),
          Text(
            'Booking Confirmed!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 20),
          _buildDetailRow('Name:', name),
          _buildDetailRow('Destination:', destination),
          _buildDetailRow(
            'Date:',
            date != null ? DateFormat('EEE, MMM d, y').format(date!) : 'Not selected',
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              primary: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              'DONE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
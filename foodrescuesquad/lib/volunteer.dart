import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart'; // Add this import

void main() => runApp(const VolunteerApp());

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Rescue Volunteer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VolunteerRegistrationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VolunteerRegistrationPage extends StatefulWidget {
  const VolunteerRegistrationPage({super.key});

  @override
  State<VolunteerRegistrationPage> createState() => _VolunteerRegistrationPageState();
}

class _VolunteerRegistrationPageState extends State<VolunteerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSubmitting = false; // Added loading state

  // Form fields
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _city = '';
  String _zipCode = '';
  bool _hasVehicle = false;
  String _vehicleType = '';
  final List<String> _availability = [];
  final List<String> _preferredTasks = [];
  String _emergencyContactName = '';
  String _emergencyContactPhone = '';

  // Available options
  final List<String> _vehicleTypes = ['Car', 'Truck', 'Van', 'Motorcycle', 'Bicycle'];
  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _taskOptions = [
    'Food Collection',
    'Food Sorting',
    'Food Delivery',
    'Administration',
    'Event Coordination',
    'Community Outreach'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Become a Volunteer'),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPersonalInfoSection(),
              const SizedBox(height: 20),
              _buildAddressSection(),
              const SizedBox(height: 20),
              _buildVehicleSection(),
              const SizedBox(height: 20),
              _buildAvailabilitySection(),
              const SizedBox(height: 20),
              _buildTasksSection(),
              const SizedBox(height: 20),
              _buildEmergencyContactSection(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // [Previous widget methods remain unchanged until _buildSubmitButton]

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'SUBMIT VOLUNTEER APPLICATION',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      // First register the user
      final userData = await ApiService.registerUser(
        firstName: _firstName,
        lastName: _lastName,
        email: _email,
        phone: _phone,
        password: 'tempPassword123', // You should add a password field
        role: 'volunteer',
      );

      // Then complete volunteer registration
      await ApiService.completeVolunteerRegistration(
        hasVehicle: _hasVehicle,
        vehicleType: _vehicleType.isNotEmpty ? _vehicleType : null,
        emergencyContactName: _emergencyContactName,
        emergencyContactPhone: _emergencyContactPhone,
        availability: _availability,
        preferredTasks: _preferredTasks,
      );

      // Show success dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text(
                'Thank you for volunteering with Food Rescue Squad! '
                'We will review your application and contact you soon.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting application: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // [Rest of the widget methods remain unchanged]
  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.volunteer_activism, size: 60, color: Colors.green[800]),
        const SizedBox(height: 10),
        Text(
          'Join Our Volunteer Squad',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green[900],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Help us rescue food and fight hunger in our community',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800]),
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your first name' : null,
              onSaved: (value) => _firstName = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your last name' : null,
              onSaved: (value) => _lastName = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  !value!.contains('@') ? 'Please enter a valid email' : null,
              onSaved: (value) => _email = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => value!.length < 10
                  ? 'Please enter a valid phone number'
                  : null,
              onSaved: (value) => _phone = value!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address Information',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800]),
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Street Address',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your address' : null,
              onSaved: (value) => _address = value!,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your city' : null,
                    onSaved: (value) => _city = value!,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'ZIP',
                      prefixIcon: Icon(Icons.markunread_mailbox),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) =>
                        value!.length != 5 ? 'Please enter a valid ZIP code' : null,
                    onSaved: (value) => _zipCode = value!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Information',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800]),
            ),
            const SizedBox(height: 15),
            SwitchListTile(
              title: const Text(
                  'Do you have a vehicle you can use for food rescue?'),
              value: _hasVehicle,
              onChanged: (bool value) {
                setState(() {
                  _hasVehicle = value;
                  if (!value) _vehicleType = '';
                });
              },
              activeColor: Colors.green,
            ),
            if (_hasVehicle) ...[
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                value: _vehicleType.isEmpty ? null : _vehicleType,
                items: _vehicleTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _vehicleType = newValue!;
                  });
                },
                validator: (value) => _hasVehicle && value == null
                    ? 'Please select your vehicle type'
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800]),
            ),
            const SizedBox(height: 10),
            const Text('Select days you are typically available:'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _daysOfWeek.map((day) {
                return FilterChip(
                  label: Text(day),
                  selected: _availability.contains(day),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _availability.add(day);
                      } else {
                        _availability.remove(day);
                      }
                    });
                  },
                  selectedColor: Colors.green[100],
                  checkmarkColor: Colors.green,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferred Tasks',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800]),
            ),
            const SizedBox(height: 10),
            const Text('Select tasks you would be interested in:'),
            const SizedBox(height: 10),
            Column(
              children: _taskOptions.map((task) {
                return CheckboxListTile(
                  title: Text(task),
                  value: _preferredTasks.contains(task),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value!) {
                        _preferredTasks.add(task);
                      } else {
                        _preferredTasks.remove(task);
                      }
                    });
                  },
                  activeColor: Colors.green,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contact',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800]),
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                prefixIcon: Icon(Icons.contact_emergency),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter emergency contact name' : null,
              onSaved: (value) => _emergencyContactName = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => value!.length < 10
                  ? 'Please enter a valid phone number'
                  : null,
              onSaved: (value) => _emergencyContactPhone = value!,
            ),
          ],
        ),
      ),
    );
  }
}
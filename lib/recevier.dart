import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/api_service.dart';

class FoodReceiverPage extends StatefulWidget {
  const FoodReceiverPage({super.key});

  @override
  _FoodReceiverPageState createState() => _FoodReceiverPageState();
}

class _FoodReceiverPageState extends State<FoodReceiverPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _foodTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedFoodCategory;
  final List<String> _foodCategories = [
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Bakery',
    'Dairy',
    'Others',
  ];

  LatLng? _donationLocation;
  String _locationStatus = "Tap to set pickup location";
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _foodRequests = [];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _foodTypeController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location services are disabled.'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are denied'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permissions are permanently denied.'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);
      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _donationLocation = LatLng(position.latitude, position.longitude);
        _locationStatus = "Location set! (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectLocationOnMap() async {
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _donationLocation ?? const LatLng(0, 0),
        ),
      ),
    );

    if (selectedLocation != null && mounted) {
      setState(() {
        _donationLocation = selectedLocation;
        _locationStatus = "Location set! (${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)})";
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_donationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please set a pickup location'),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare address data
      final address = {
        'street': _addressController.text,
        'city': 'Your City', // You might want to get this from geocoding
        'state': 'Your State',
        'zipCode': 'Your Zip',
        'latitude': _donationLocation!.latitude,
        'longitude': _donationLocation!.longitude,
      };

      // Call API to create food request
      await ApiService.createFoodRequest(
        foodCategory: _selectedFoodCategory!,
        foodType: _foodTypeController.text,
        quantity: _quantityController.text,
        address: address,
        neededBy: DateTime.now().add(const Duration(days: 1)),
      );

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Food Request Submitted Successfully!'),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Clear form after submission
      _formKey.currentState?.reset();
      setState(() {
        _selectedFoodCategory = null;
        _donationLocation = null;
        _locationStatus = "Tap to set pickup location";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: ${e.toString()}'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addFoodRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_donationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please set a pickup location'),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare address data
      final address = {
        'street': _addressController.text,
        'city': 'Your City',
        'state': 'Your State',
        'zipCode': 'Your Zip',
        'latitude': _donationLocation!.latitude,
        'longitude': _donationLocation!.longitude,
      };

      // Call API to create food request
      await ApiService.createFoodRequest(
        foodCategory: _selectedFoodCategory!,
        foodType: _foodTypeController.text,
        quantity: _quantityController.text,
        address: address,
        neededBy: DateTime.now().add(const Duration(days: 1)),
      );

      // Create local request object
      final newRequest = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'receiverName': _nameController.text,
        'phone': _phoneController.text,
        'foodType': _foodTypeController.text,
        'foodCategory': _selectedFoodCategory ?? 'Uncategorized',
        'quantity': _quantityController.text,
        'address': _addressController.text,
        'latitude': _donationLocation!.latitude,
        'longitude': _donationLocation!.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _foodRequests.add(newRequest);
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Food request added successfully! Donors will be notified.'),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // In a real app, you would navigate to requests list
            },
          ),
        ),
      );

      // Clear form with animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _formKey.currentState?.reset();
          setState(() {
            _selectedFoodCategory = null;
            _donationLocation = null;
            _locationStatus = "Tap to set pickup location";
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Receiver Form'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header with icon
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Icon(Icons.food_bank, 
                      size: 60, 
                      color: Colors.green[700]),
                    const SizedBox(height: 10),
                    const Text(
                      'Request Food Donation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Fill the form to receive food donations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Food Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFoodCategory,
                decoration: const InputDecoration(
                  labelText: 'Food Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _foodCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFoodCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a food category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Food Type Field
              TextFormField(
                controller: _foodTypeController,
                decoration: const InputDecoration(
                  labelText: 'Food Type (e.g., Rice, Bread, etc.)',
                  prefixIcon: Icon(Icons.fastfood),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the type of food';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Quantity Field
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g., 5 kg, 10 plates, etc.)',
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Address Field with TypeAhead
              TypeAheadField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  return [];
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion.toString()),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _addressController.text = suggestion.toString();
                },
              ),
              const SizedBox(height: 16),
              
              // Location Card with Interactive Elements
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_pin, 
                            color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Pickup Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _locationStatus,
                        style: TextStyle(
                          color: _donationLocation == null 
                            ? Colors.grey[600] 
                            : Colors.green[700],
                          fontWeight: _donationLocation == null 
                            ? FontWeight.normal 
                            : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _getCurrentLocation,
                            icon: Icon(Icons.my_location, 
                              color: _isSubmitting ? Colors.grey : Colors.white),
                            label: Text(
                              _isSubmitting ? 'Locating...' : 'Current Location',
                              style: TextStyle(
                                color: _isSubmitting ? Colors.grey : Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectLocationOnMap,
                            icon: const Icon(Icons.map, 
                              color: Colors.white),
                            label: const Text(
                              'Select on Map',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Additional Notes Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (e.g., dietary restrictions)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              
              // Submit Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
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
                              'Submit Donation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _addFoodRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
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
                              'Add Request (Notify Donors)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapLocationPicker extends StatefulWidget {
  final LatLng initialLocation;

  const MapLocationPicker({super.key, required this.initialLocation});

  @override
  _MapLocationPickerState createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late GoogleMapController _mapController;
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Drop Location'),
        backgroundColor: Colors.green[700],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedLocation);
            },
            child: const Text(
              'CONFIRM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (LatLng location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
              markers: {
                Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: _selectedLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                ),
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Embed the Google Maps iframe here
          const HtmlElementView(
            viewType: 'web/maps',
          ),
        ],
      ),
    );
  }
}
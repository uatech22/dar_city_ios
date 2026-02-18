import 'package:dar_city_app/models/country.dart';
import 'package:dar_city_app/models/order.dart';
import 'package:dar_city_app/services/delivery_service.dart';
import 'package:dar_city_app/services/location_service.dart';
import 'package:dar_city_app/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'loginScreen.dart';
import 'payment_screen.dart';

class DeliveryInformationScreen extends StatefulWidget {
  final Order order;
  const DeliveryInformationScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<DeliveryInformationScreen> createState() => _DeliveryInformationScreenState();
}

class _DeliveryInformationScreenState extends State<DeliveryInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeliveryService _deliveryService = DeliveryService();
  final LocationService _locationService = LocationService();
  bool _isLoading = false;

  // Text Controllers
  final fullNameController = TextEditingController();
  final streetAddressController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final phoneController = TextEditingController();

  // State for dropdowns
  List<Country> _countries = [];
  List<String> _regions = [];
  Country? _selectedCountry;
  String? _selectedRegion;
  bool _isRegionsLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    streetAddressController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    try {
      final countries = await _locationService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> _fetchRegions(String countryIso2) async {
    setState(() {
      _isRegionsLoading = true;
      _regions = [];
      _selectedRegion = null;
    });
    try {
      final regions = await _locationService.getRegions(countryIso2);
      if (mounted) {
        setState(() {
          _regions = regions;
          _isRegionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegionsLoading = false;
        });
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Authentication Required', style: TextStyle(color: Colors.white)),
          content: const Text('You need to be logged in to save delivery information.', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Go to Login'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final token = SessionManager().getToken();
    if (token == null) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _deliveryService.saveDeliveryInfo(
        orderId: widget.order.id,
        fullName: fullNameController.text,
        streetAddress: streetAddressController.text,
        city: _selectedRegion!, // Using region for city
        state: stateController.text,
        postalCode: postalCodeController.text,
        country: _selectedCountry!.name,
        phone: phoneController.text,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompletePaymentScreen(order: widget.order),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save delivery info: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Information'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: <Widget>[
                    const Text(
                      'Provide delivery information for your merchandise.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Full Name', controller: fullNameController),
                    _buildTextField(label: 'Street Address', controller: streetAddressController),
                    const SizedBox(height: 8),
                    _buildCountryDropdown(),
                    const SizedBox(height: 8),
                    _buildRegionDropdown(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                         Expanded(child: _buildTextField(label: 'State/Province', controller: stateController)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            label: 'Postal Code',
                            controller: postalCodeController,
                            keyboardType: TextInputType.number,
                            isNumeric: true,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      label: 'Contact Phone Number',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      isNumeric: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveAndContinue,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Save and Continue'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<Country>(
      value: _selectedCountry,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Country'),
      items: _countries.map((Country country) {
        return DropdownMenuItem<Country>(
          value: country,
          child: Text(country.name),
        );
      }).toList(),
      onChanged: (Country? newValue) {
        setState(() {
          _selectedCountry = newValue;
          if (newValue != null) {
            _fetchRegions(newValue.iso2);
          }
        });
      },
      validator: (value) => value == null ? 'Please select a country' : null,
    );
  }

  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRegion,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Region'),
      items: _regions.map((String region) {
        return DropdownMenuItem<String>(
          value: region,
          child: Text(region),
        );
      }).toList(),
      onChanged: _selectedCountry == null
          ? null
          : (String? newValue) {
              setState(() {
                _selectedRegion = newValue;
              });
            },
      validator: (value) => value == null ? 'Please select a region' : null,
      disabledHint: const Text('Select a country first', style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          if (isNumeric && int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
    );
  }
}

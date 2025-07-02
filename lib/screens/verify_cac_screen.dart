import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/agency_api.dart';

/// Screen for verifying company/business registration with CAC
class VerifyCacScreen extends StatefulWidget {
  const VerifyCacScreen({Key? key}) : super(key: key);

  @override
  State<VerifyCacScreen> createState() => _VerifyCacScreenState();
}

class _VerifyCacScreenState extends State<VerifyCacScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _agencyApi = AgencyApi();
  
  bool _isLoading = false;
  bool _isVerified = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _rcNumber = '';
  String _officialName = '';

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  // Validate and submit the form
  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _verifyCompany(_companyNameController.text);
    }
  }

  // Verify the company name with CAC
  Future<void> _verifyCompany(String companyName) async {
    setState(() {
      _isLoading = true;
      _isVerified = false;
      _hasError = false;
      _errorMessage = '';
      _rcNumber = '';
      _officialName = '';
    });

    try {
      // Call the API to verify the company
      final result = await _agencyApi.verifyAgency(companyName);
      
      // Log the full response for debugging
      print('CAC Verification API response: $result');
      
      if (result['success'] == true) {
        final body = result['body'];
        
        if (body['status'] == 'verified') {
          // Company is verified
          setState(() {
            _isLoading = false;
            _isVerified = true;
            _rcNumber = body['rc_number'] ?? 'Not provided';
            _officialName = body['official_name'] ?? companyName;
          });
          
          // Show success message
          _showSnackBar('Company verified successfully!', Colors.green);
        } else {
          // Company not found
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Company not found in CAC records. Please check the name and try again.';
          });
        }
      } else {
        // API error
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = result['body']['error'] ?? 'Failed to verify company. Please try again.';
        });
      }
    } catch (e) {
      // Exception
      print('Exception during CAC verification: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  // Show snackbar message
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  // Reset the form
  void _resetForm() {
    setState(() {
      _companyNameController.clear();
      _isVerified = false;
      _hasError = false;
      _errorMessage = '';
      _rcNumber = '';
      _officialName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verify CAC',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Company Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the company name to verify its registration with the Corporate Affairs Commission (CAC) of Nigeria.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _companyNameController,
                        decoration: InputDecoration(
                          labelText: 'Company/Business Name',
                          hintText: 'e.g. TECHTASKER SOLUTIONS LIMITED',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a company name';
                          }
                          if (value.length < 3) {
                            return 'Company name must be at least 3 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (_) => _submitForm(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFFF39322),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Verify',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          if (_isVerified || _hasError) ...[
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: _resetForm,
                              child: const Text('Reset'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Results
              if (_isVerified)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verification Successful',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Company Name:', _officialName),
                      const SizedBox(height: 8),
                      _buildInfoRow('RC Number:', _rcNumber),
                      const SizedBox(height: 8),
                      _buildInfoRow('Status:', 'ACTIVE'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              // Copy details to clipboard
                              final text = 'Company: $_officialName\nRC Number: $_rcNumber\nStatus: ACTIVE';
                              Clipboard.setData(ClipboardData(text: text));
                              
                              // Show snackbar
                              _showSnackBar('Copied to clipboard', Colors.blue);
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Share details
                              // (In a real app, you would implement a share feature here)
                              _showSnackBar('Share feature coming soon', Colors.blue);
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              if (_hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verification Failed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Suggestions:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Check the company name spelling'),
                      const Text('• Include "LIMITED" or "LTD" if applicable'),
                      const Text('• Try the full registered business name'),
                    ],
                  ),
                ),
                
              const SizedBox(height: 24),
              
              // Information about CAC
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About CAC Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The Corporate Affairs Commission (CAC) is responsible for the registration of businesses in Nigeria. This verification service checks if a company is officially registered with the CAC.',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Open CAC website
                        // (In a real app, you would implement URL launching here)
                        _showSnackBar('Opening CAC website', Colors.blue);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Visit CAC Website'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
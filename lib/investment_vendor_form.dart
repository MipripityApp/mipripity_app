import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'investment_submission_success.dart';

class InvestmentVendorForm extends StatefulWidget {
  const InvestmentVendorForm({super.key});

  @override
  State<InvestmentVendorForm> createState() => _InvestmentVendorFormState();
}

class _InvestmentVendorFormState extends State<InvestmentVendorForm> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;
  bool isSubmitting = false;
  
  // Form controllers
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  
  final _projectTitleController = TextEditingController();
  final _projectDescriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _minInvestmentController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _expectedReturnController = TextEditingController();
  final _durationController = TextEditingController();
  
  // Form data
  String selectedProjectType = 'Residential';
  List<String> selectedFeatures = [];
  List<String> uploadedImages = [];
  bool agreeToTerms = false;
  
  final List<String> projectTypes = [
    'Residential',
    'Commercial',
    'Mixed-Use',
    'Industrial',
    'Retail',
    'Office Space'
  ];
  
  final List<String> availableFeatures = [
    'Swimming Pool',
    'Gym/Fitness Center',
    '24/7 Security',
    'Parking Space',
    'Green Building',
    'Smart Home Features',
    'Playground',
    'Shopping Center',
    'School Nearby',
    'Hospital Nearby',
    'Public Transport',
    'Beach Access',
    'Mountain View',
    'City View'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Investment Opportunity Form',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF000080),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: currentStep,
          onStepTapped: (step) {
            // Only allow tapping on completed steps or current step
            if (step <= currentStep) {
              setState(() {
                currentStep = step;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  // Next/Submit Button
                  if (details.stepIndex < 2)
                    ElevatedButton(
                      onPressed: () => _handleNext(details.stepIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39322),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Next'),
                    ),
                  if (details.stepIndex == 2)
                    ElevatedButton(
                      onPressed: isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: isSubmitting 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit'),
                    ),
                  const SizedBox(width: 12),
                  
                  // Back Button
                  if (details.stepIndex > 0)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentStep = details.stepIndex - 1;
                        });
                      },
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Color(0xFF000080)),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Company Information
            Step(
              title: const Text('Company Information'),
              content: _buildCompanyInfoStep(),
              isActive: currentStep >= 0,
              state: _getStepState(0),
            ),
            // Step 2: Investment Details
            Step(
              title: const Text('Investment Details'),
              content: _buildInvestmentDetailsStep(),
              isActive: currentStep >= 1,
              state: _getStepState(1),
            ),
            // Step 3: Review & Submit
            Step(
              title: const Text('Review & Submit'),
              content: _buildReviewStep(),
              isActive: currentStep >= 2,
              state: _getStepState(2),
            ),
          ],
        ),
      ),
    );
  }

  StepState _getStepState(int stepIndex) {
    if (stepIndex < currentStep) {
      return StepState.complete;
    } else if (stepIndex == currentStep) {
      return StepState.indexed;
    } else {
      return StepState.disabled;
    }
  }

  void _handleNext(int stepIndex) {
    if (stepIndex == 0) {
      // Validate Company Information
      if (_validateCompanyInfo()) {
        setState(() {
          currentStep = 1;
        });
      }
    } else if (stepIndex == 1) {
      // Validate Investment Details
      if (_validateInvestmentDetails()) {
        setState(() {
          currentStep = 2;
        });
      }
    }
  }

  bool _validateCompanyInfo() {
    // Check if all required company fields are filled
    if (_companyNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter company name');
      return false;
    }
    if (_contactPersonController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter contact person name');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter email address');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter phone number');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter company address');
      return false;
    }
    if (_licenseNumberController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter license/registration number');
      return false;
    }
    return true;
  }

  bool _validateInvestmentDetails() {
    // Check if all required investment fields are filled
    if (_projectTitleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter project title');
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter project location');
      return false;
    }
    if (_projectDescriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter project description');
      return false;
    }
    if (_minInvestmentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter minimum investment amount');
      return false;
    }
    if (_totalAmountController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter total amount needed');
      return false;
    }
    if (_expectedReturnController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter expected return');
      return false;
    }
    if (_durationController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter investment duration');
      return false;
    }
    
    // Validate that min investment is less than total amount
    final minInvestment = int.tryParse(_minInvestmentController.text.trim()) ?? 0;
    final totalAmount = int.tryParse(_totalAmountController.text.trim()) ?? 0;
    
    if (minInvestment >= totalAmount) {
      _showErrorSnackBar('Minimum investment must be less than total amount');
      return false;
    }
    
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCompanyInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company/Firm Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Company/Firm Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _contactPersonController,
          decoration: const InputDecoration(
            labelText: 'Contact Person *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Company Address *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.web),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _licenseNumberController,
          decoration: const InputDecoration(
            labelText: 'License/Registration Number *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.verified),
          ),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All information will be verified before approval',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Investment Opportunity Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _projectTitleController,
          decoration: const InputDecoration(
            labelText: 'Project Title *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: selectedProjectType,
          decoration: const InputDecoration(
            labelText: 'Project Type *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: projectTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedProjectType = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Project Location *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _projectDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Project Description *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minInvestmentController,
                decoration: const InputDecoration(
                  labelText: 'Min Investment (₦) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _totalAmountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount (₦) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expectedReturnController,
                decoration: const InputDecoration(
                  labelText: 'Expected Return (%) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
                  hintText: 'e.g., 12-15% annually',
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  hintText: 'e.g., 1-5 years',
                ),
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        const Text(
          'Project Features',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableFeatures.map((feature) {
            final isSelected = selectedFeatures.contains(feature);
            return FilterChip(
              label: Text(feature),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedFeatures.add(feature);
                  } else {
                    selectedFeatures.remove(feature);
                  }
                });
              },
              selectedColor: const Color(0xFFF39322).withOpacity(0.3),
              checkmarkColor: const Color(0xFF000080),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // Image upload section
        const Text(
          'Project Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _handleImageUpload,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Tap to upload project images',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Maximum 5 images',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                if (uploadedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${uploadedImages.length} image(s) selected',
                    style: const TextStyle(
                      color: Color(0xFF000080),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Company Info Summary
        _buildSummaryCard(
          'Company Information',
          [
            'Company: ${_companyNameController.text}',
            'Contact: ${_contactPersonController.text}',
            'Email: ${_emailController.text}',
            'Phone: ${_phoneController.text}',
            'Address: ${_addressController.text}',
            if (_websiteController.text.isNotEmpty) 'Website: ${_websiteController.text}',
            'License: ${_licenseNumberController.text}',
          ],
          Icons.business,
        ),
        const SizedBox(height: 16),
        
        // Investment Details Summary
        _buildSummaryCard(
          'Investment Details',
          [
            'Project: ${_projectTitleController.text}',
            'Type: $selectedProjectType',
            'Location: ${_locationController.text}',
            'Description: ${_projectDescriptionController.text.length > 100 ? '${_projectDescriptionController.text.substring(0, 100)}...' : _projectDescriptionController.text}',
            'Min Investment: ₦${_formatNumber(_minInvestmentController.text)}',
            'Total Amount: ₦${_formatNumber(_totalAmountController.text)}',
            'Expected Return: ${_expectedReturnController.text}',
            'Duration: ${_durationController.text}',
            if (selectedFeatures.isNotEmpty) 'Features: ${selectedFeatures.join(', ')}',
            if (uploadedImages.isNotEmpty) 'Images: ${uploadedImages.length} uploaded',
          ],
          Icons.money,
        ),
        const SizedBox(height: 24),
        
        // Terms and Conditions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    agreeToTerms = value ?? false;
                  });
                },
                title: const Text(
                  'I agree to the Terms and Conditions',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'By submitting, you agree to our platform terms, investment guidelines, and verification process.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF000080),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your information is secure and will only be used for verification purposes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Review Process',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your investment opportunity will be reviewed by our team within 2-3 business days. You will receive an email notification once the review is complete.',
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<String> items, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF000080)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.where((item) => item.split(': ').length > 1 && item.split(': ')[1].isNotEmpty).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF39322),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  String _formatNumber(String number) {
    if (number.isEmpty) return '0';
    final num = int.tryParse(number) ?? 0;
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _handleImageUpload() {
    // Simulate image upload
    setState(() {
      uploadedImages.add('image_${uploadedImages.length + 1}.jpg');
    });
    _showSuccessSnackBar('Image uploaded successfully');
  }

  void _submitForm() async {
    if (!agreeToTerms) {
      _showErrorSnackBar('Please agree to the terms and conditions');
      return;
    }

    // Final validation
    if (!_validateCompanyInfo() || !_validateInvestmentDetails()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Navigate to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const InvestmentSubmissionSuccess(),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Submission failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _licenseNumberController.dispose();
    _projectTitleController.dispose();
    _projectDescriptionController.dispose();
    _locationController.dispose();
    _minInvestmentController.dispose();
    _totalAmountController.dispose();
    _expectedReturnController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}

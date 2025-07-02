import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'investment_success_screen.dart';

class InvestmentCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> investment;
  final int? initialAmount;

  const InvestmentCheckoutScreen({
    Key? key,
    required this.investment,
    this.initialAmount,
  }) : super(key: key);

  @override
  _InvestmentCheckoutScreenState createState() => _InvestmentCheckoutScreenState();
}

class _InvestmentCheckoutScreenState extends State<InvestmentCheckoutScreen> {
  int investmentAmount = 0;
  String selectedPaymentMethod = 'card';
  bool agreeToTerms = false;
  bool isProcessing = false;
  
  final TextEditingController _amountController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    investmentAmount = widget.initialAmount ?? widget.investment['minInvestment'];
    _amountController.text = investmentAmount.toString();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  // Format price to Nigerian Naira
  String formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    ).format(price);
  }
  
  void processPayment() {
    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions')),
      );
      return;
    }
    
    if (investmentAmount < widget.investment['minInvestment']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount must be at least ${formatPrice(widget.investment['minInvestment'])}')),
      );
      return;
    }
    
    setState(() {
      isProcessing = true;
    });
    
    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isProcessing = false;
      });
      
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InvestmentSuccessScreen(
            investment: widget.investment,
            amount: investmentAmount,
          ),
        ),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Investment',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF000080)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Investment summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Investment Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.investment['images'][0],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.investment['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.investment['location'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      size: 14,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.investment['expectedReturn'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Investment amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Investment Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '₦ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Enter amount',
                        ),
                        onChanged: (value) {
                          setState(() {
                            investmentAmount = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum investment: ${formatPrice(widget.investment['minInvestment'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Payment method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Card payment option
                      _buildPaymentOption(
                        'card',
                        'Credit/Debit Card',
                        'Pay securely with your card',
                        Icons.credit_card,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Bank transfer option
                      _buildPaymentOption(
                        'bank',
                        'Bank Transfer',
                        'Transfer from your bank account',
                        Icons.account_balance,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // USSD option
                      _buildPaymentOption(
                        'ussd',
                        'USSD Payment',
                        'Pay using USSD code',
                        Icons.dialpad,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Terms and conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: agreeToTerms,
                      activeColor: const Color(0xFFF39322),
                      onChanged: (value) {
                        setState(() {
                          agreeToTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'I agree to the terms and conditions of this investment, including the risk disclosure statement.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
          
          // Bottom payment button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        formatPrice(investmentAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39322),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : const Text('Complete Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentOption(String value, String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedPaymentMethod == value
                ? const Color(0xFFF39322)
                : Colors.grey.shade300,
            width: selectedPaymentMethod == value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedPaymentMethod == value
                    ? const Color(0xFFF39322).withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selectedPaymentMethod == value
                    ? const Color(0xFFF39322)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio(
              value: value,
              groupValue: selectedPaymentMethod,
              activeColor: const Color(0xFFF39322),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPaymentMethod = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'investment_checkout_screen.dart';

class InvestmentCalculatorScreen extends StatefulWidget {
  final Map<String, dynamic> investment;

  const InvestmentCalculatorScreen({
    Key? key,
    required this.investment,
  }) : super(key: key);

  @override
  _InvestmentCalculatorScreenState createState() => _InvestmentCalculatorScreenState();
}

class _InvestmentCalculatorScreenState extends State<InvestmentCalculatorScreen> {
  int investmentAmount = 0;
  double? calculatedProfit;
  double? calculatedTotalReturn;
  double? annualReturn;
  int investmentDuration = 1;
  
  final TextEditingController _amountController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    investmentAmount = widget.investment['minInvestment'];
    _amountController.text = investmentAmount.toString();
    calculateProfit();
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
  
  void calculateProfit() {
    if (investmentAmount <= 0) {
      setState(() {
        calculatedProfit = null;
        calculatedTotalReturn = null;
        annualReturn = null;
      });
      return;
    }

    // Parse the expected return percentage
    RegExp returnRegExp = RegExp(r'(\d+)-(\d+)');
    var returnMatch = returnRegExp.firstMatch(widget.investment['expectedReturn']);
    if (returnMatch == null) return;

    int minReturn = int.parse(returnMatch.group(1)!);
    int maxReturn = int.parse(returnMatch.group(2)!);
    
    // Calculate average return
    double avgReturn = (minReturn + maxReturn) / 2 / 100;
    
    // Extract duration
    RegExp durationRegExp = RegExp(r'(\d+)-(\d+)');
    var durationMatch = durationRegExp.firstMatch(widget.investment['duration']);
    if (durationMatch == null) return;
    
    int minDuration = int.parse(durationMatch.group(1)!);
    int maxDuration = int.parse(durationMatch.group(2)!);
    
    // Use selected duration or average if not set
    double years = investmentDuration > 0 ? 
        investmentDuration.toDouble() : 
        (minDuration + maxDuration) / 2;
    
    // Calculate estimated profit (compound interest)
    num totalReturn = investmentAmount * Math.pow((1 + avgReturn), years);
    num profit = totalReturn - investmentAmount;
    
    setState(() {
      calculatedProfit = profit as double?;
      calculatedTotalReturn = totalReturn as double?;
      annualReturn = avgReturn * 100;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Investment Calculator',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF000080)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000080),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.investment['expectedReturn'],
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Calculator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Investment Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 4),
                  Text(
                    'Minimum investment: ${formatPrice(widget.investment['minInvestment'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Investment Duration (Years)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Duration slider
                  Column(
                    children: [
                      Slider(
                        value: investmentDuration.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: const Color(0xFFF39322),
                        inactiveColor: Colors.grey.shade300,
                        label: investmentDuration.toString(),
                        onChanged: (value) {
                          setState(() {
                            investmentDuration = value.round();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1 year',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$investmentDuration years',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '10 years',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: calculateProfit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Calculate Return'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results
            if (calculatedProfit != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                    
                    _buildResultRow(
                      'Initial Investment',
                      formatPrice(investmentAmount),
                      Colors.grey.shade700,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildResultRow(
                      'Annual Return Rate',
                      '${annualReturn?.toStringAsFixed(1)}%',
                      Colors.blue.shade700,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildResultRow(
                      'Investment Period',
                      '$investmentDuration years',
                      Colors.grey.shade700,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildResultRow(
                      'Estimated Profit',
                      formatPrice(calculatedProfit!.round()),
                      const Color(0xFFF39322),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildResultRow(
                      'Total Return',
                      formatPrice(calculatedTotalReturn!.round()),
                      Colors.green.shade700,
                      isBold: true,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is an estimate based on the provided information. Actual returns may vary based on market conditions.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvestmentCheckoutScreen(
                                investment: widget.investment,
                                initialAmount: investmentAmount,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF39322),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Proceed to Invest'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
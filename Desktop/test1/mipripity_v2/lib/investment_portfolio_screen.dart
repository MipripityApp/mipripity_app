import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' show cos, sin, pi;
import 'dart:ui' as ui;

// Custom chart section classes
class PieSection {
  final double value;
  final Color color;
  
  PieSection({required this.value, required this.color});
}

// Custom chart painters
class PerformanceChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double minValue;

  PerformanceChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF39322)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
      
    final fillPaint = Paint()
      ..color = const Color(0xFFF39322).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final fillPath = Path();
      
    // Calculate points
    final double xStep = size.width / (data.length - 1);
    final double yRange = maxValue - minValue;
    
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      final double normalizedY = (data[i]['value'] - minValue) / yRange;
      final double y = size.height - (normalizedY * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
      
    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    // Draw
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
      
    // Draw month labels
    final textStyle = TextStyle(color: Colors.grey.shade600, fontSize: 10);
    
    for (int i = 0; i < data.length; i += 2) { // Draw every other label to avoid crowding
      final double x = i * xStep;
      final String month = data[i]['month'];
      
      final textSpan = TextSpan(text: month, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final List<PieSection> sections;
  
  PieChartPainter({required this.sections});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 * 0.8 : size.height / 2 * 0.8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    double total = sections.fold(0, (sum, section) => sum + section.value);
    double startAngle = -90 * (pi / 180); // Start from top (in radians)
      
    for (var section in sections) {
      final sweepAngle = (section.value / total) * 2 * pi;
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
        
      // Draw percentage text
      final percentage = (section.value / total * 100).round();
      final textSpan = TextSpan(
        text: '$percentage%',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
        
      // Position text in the middle of the arc
      final textAngle = startAngle + (sweepAngle / 2);
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);
      
      textPainter.paint(canvas, Offset(textX - textPainter.width / 2, textY - textPainter.height / 2));
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({super.key});

  @override
  _InvestmentPortfolioScreenState createState() => _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends State<InvestmentPortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String activeTab = "invest";
  String timeFilter = "1Y"; // 1M, 6M, 1Y, All
  
  // Sample portfolio data
  final Map<String, dynamic> portfolioData = {
    'totalInvested': 2750000,
    'currentValue': 3125000,
    'totalProfit': 375000,
    'profitPercentage': 13.6,
    'monthlyIncome': 28750,
    'investments': [
      {
        'id': 'inv-001',
        'title': 'Oceanview Luxury Apartments',
        'location': 'Banana Island, Lagos',
        'investedAmount': 1500000,
        'currentValue': 1725000,
        'profit': 225000,
        'profitPercentage': 15.0,
        'status': 'Active',
        'startDate': '2023-05-15',
        'duration': '3 years',
        'image': 'https://b2435771.smushcdn.com/2435771/wp-content/uploads/2023/10/Ocean-View-5-Marbella-MDR-Luxury-Homes-1170x785.jpg?lossy=2&strip=1&webp=1',
      },
      {
        'id': 'inv-002',
        'title': 'Downtown Commercial Complex',
        'location': 'Porthacourt, Porthacourt',
        'investedAmount': 750000,
        'currentValue': 825000,
        'profit': 75000,
        'profitPercentage': 10.0,
        'status': 'Active',
        'startDate': '2023-08-22',
        'duration': '5 years',
        'image': 'https://www.royalerealtorsindia.com/wp-content/uploads/2025/01/4.jpg',
      },
      {
        'id': 'inv-003',
        'title': 'Suburban Housing Development',
        'location': 'Abuja City, F.C.T',
        'investedAmount': 500000,
        'currentValue': 575000,
        'profit': 75000,
        'profitPercentage': 15.0,
        'status': 'Active',
        'startDate': '2023-10-05',
        'duration': '4 years',
        'image': 'https://www.ft.com/__origami/service/image/v2/images/raw/https%3A%2F%2Fd1e00ek4ebabms.cloudfront.net%2Fproduction%2F70d51010-e1df-462c-9a7f-694236de29a0.jpg?source=next-article&fit=scale-down&quality=highest&width=700&dpr=1',
      },
    ],
    'performanceData': [
      {'month': 'Jan', 'value': 2750000},
      {'month': 'Feb', 'value': 2800000},
      {'month': 'Mar', 'value': 2825000},
      {'month': 'Apr', 'value': 2875000},
      {'month': 'May', 'value': 2950000},
      {'month': 'Jun', 'value': 3000000},
      {'month': 'Jul', 'value': 3050000},
      {'month': 'Aug', 'value': 3075000},
      {'month': 'Sep', 'value': 3100000},
      {'month': 'Oct', 'value': 3125000},
      {'month': 'Nov', 'value': 3125000},
      {'month': 'Dec', 'value': 3125000},
    ],
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Format price to Nigerian Naira
  String formatPrice(num amount, {String symbol = '₦'}) {
    if (amount >= 1e9) {
      return '$symbol${(amount / 1e9).toStringAsFixed(1)}B';
    } else if (amount >= 1e6) {
      return '$symbol${(amount / 1e6).toStringAsFixed(1)}M';
    } else if (amount >= 1e3) {
      return '$symbol${(amount / 1e3).toStringAsFixed(1)}K';
    } else {
      return '$symbol$amount';
    }
  }
  
  // Format date string to readable format
  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }
  
  // Handle bottom navigation tab change
  void handleTabChange(String tab) {
    setState(() {
      activeTab = tab;
    });
    
    // Navigation logic would go here
    if (tab == 'home') {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (tab == 'invest') {
      Navigator.pushReplacementNamed(context, '/invest');
    } else if (tab == 'add') {
      Navigator.pushNamed(context, '/add');
    } else if (tab == 'chat') {
      // Navigate to chat
    } else if (tab == 'explore') {
      Navigator.pushReplacementNamed(context, '/explore');
    }
  }
  
  // Build performance chart
  Widget _buildPerformanceChart() {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: PerformanceChartPainter(
          data: portfolioData['performanceData'],
          maxValue: 3200000,
          minValue: 2700000,
        ),
        size: Size.infinite,
      ),
    );
  }

  // Build investment breakdown chart
  Widget _buildInvestmentBreakdownChart() {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: PieChartPainter(
          sections: [
            PieSection(value: 55, color: const Color(0xFF000080)),
            PieSection(value: 27, color: const Color(0xFFF39322)),
            PieSection(value: 18, color: Colors.green.shade600),
          ],
        ),
        size: Size.infinite,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'My Portfolio',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF000080)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF39322),
          labelColor: const Color(0xFF000080),
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Investments'),
            Tab(text: 'Performance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Investments Tab
          _buildInvestmentsTab(),
          
          // Performance Tab
          _buildPerformanceTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildInvestmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio summary
          Container(
            padding: const EdgeInsets.all(20),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Invested',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatPrice(portfolioData['totalInvested']),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Current Value',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatPrice(portfolioData['currentValue']),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      'Total Profit',
                      formatPrice(portfolioData['totalProfit']),
                      Colors.green.shade700,
                    ),
                    _buildSummaryItem(
                      'Return Rate',
                      '${portfolioData['profitPercentage']}%',
                      const Color(0xFFF39322),
                    ),
                    _buildSummaryItem(
                      'Monthly Income',
                      formatPrice(portfolioData['monthlyIncome']),
                      Colors.blue.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Investments list
          const Text(
            'Your Investments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          ...portfolioData['investments'].map<Widget>((investment) {
            return _buildInvestmentCard(investment);
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time filter
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeFilterButton('1M'),
                _buildTimeFilterButton('6M'),
                _buildTimeFilterButton('1Y'),
                _buildTimeFilterButton('All'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Performance chart
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
                  'Portfolio Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatPrice(portfolioData['currentValue']),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.green.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${portfolioData['profitPercentage']}%',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: _buildPerformanceChart(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Investment breakdown
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
                  'Investment Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 200,
                        child: _buildInvestmentBreakdownChart(),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildLegendItem(
                            'Oceanview Luxury Apartments',
                            '55%',
                            const Color(0xFF000080),
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            'Downtown Commercial Complex',
                            '27%',
                            const Color(0xFFF39322),
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            'Suburban Housing Development',
                            '18%',
                            Colors.green.shade600,
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
          
          // Investment stats
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
                  'Investment Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Investments', '3'),
                const SizedBox(height: 12),
                _buildStatRow('Average Return Rate', '${portfolioData['profitPercentage']}%'),
                const SizedBox(height: 12),
                _buildStatRow('Projected Annual Income', formatPrice(portfolioData['monthlyIncome'] * 12)),
                const SizedBox(height: 12),
                _buildStatRow('Total Profit', formatPrice(portfolioData['totalProfit'])),
              ],
            ),
          ),
          
          const SizedBox(height: 80), // Space for bottom nav
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInvestmentCard(Map<String, dynamic> investment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Header with image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Image.network(
                  investment['image'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              investment['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000080),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              investment['status'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                              investment['location'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Since ${formatDate(investment['startDate'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 1),
          
          // Investment details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invested',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatPrice(investment['investedAmount']),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Value',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatPrice(investment['currentValue']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '+${investment['profitPercentage']}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF39322),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_upward,
                                color: Color(0xFFF39322),
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // View investment details
                      Navigator.pushNamed(
                        context, 
                        '/investment-details/${investment['id']}'
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeFilterButton(String period) {
    bool isActive = timeFilter == period;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          timeFilter = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF000080) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          percentage,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem("home", Icons.home, "Home"),
            _buildNavItem("invest", Icons.trending_up, "Invest"),
            _buildNavItem("add", Icons.add_circle, "Add"),
            _buildNavItem("chat", Icons.chat_bubble, "Chat"),
            _buildNavItem("explore", Icons.explore, "Explore"),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavItem(String tab, IconData icon, String label) {
    bool isActive = activeTab == tab;
    
    return InkWell(
      onTap: () => handleTabChange(tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFF39322) : Colors.grey,
            size: tab == "add" ? 32 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFF39322) : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
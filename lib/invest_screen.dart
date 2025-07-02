import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'shared/bottom_navigation.dart';

// Define investment model class
class Investment {
  final String id;
  final String title;
  final String location;
  final String description;
  final String realtorName;
  final String realtorImage;
  final int minInvestment;
  final String expectedReturn;
  final String duration;
  final int investors;
  final int remainingAmount;
  final int totalAmount;
  final List<String> images;
  final List<String> features;

  Investment({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.realtorName,
    required this.realtorImage,
    required this.minInvestment,
    required this.expectedReturn,
    required this.duration,
    required this.investors,
    required this.remainingAmount,
    required this.totalAmount,
    required this.images,
    required this.features,
  });
}

class InvestInRealEstate extends StatefulWidget {
  const InvestInRealEstate({super.key});

  @override
  _InvestInRealEstateState createState() => _InvestInRealEstateState();
}

class _InvestInRealEstateState extends State<InvestInRealEstate> {
  String activeTab = "invest";
  String searchQuery = "";
  List<Investment> investments = [];
  List<Investment> filteredInvestments = [];
  bool showCalculator = false;
  Investment? selectedInvestment;
  int investmentAmount = 0;
  double? calculatedProfit;
  
  // Details modal states
  bool showDetailsModal = false;
  int imageIndex = 0;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize sample investments
    investments = sampleInvestments;
    filteredInvestments = investments;
  }

  // Sample investments data
  List<Investment> sampleInvestments = [
    Investment(
      id: "inv-001",
      title: "Oceanview Luxury Apartments",
      location: "Banana Island, Lagos",
      description: "Premium luxury apartments with ocean views and top-tier amenities. High rental demand in a prime tourist destination.",
      realtorName: "Garuda Property",
      realtorImage: "https://content.jdmagicbox.com/comp/mysore/i1/0821px821.x821.230614200542.e3i1/catalogue/garuda-properties-kuvempunagar-mysore-estate-agents-xg25231joc.jpg",
      minInvestment: 500000,
      expectedReturn: "12-15% annually",
      duration: "1-5 years",
      investors: 47,
      remainingAmount: 250000,
      totalAmount: 2000000,
      images: ["https://b2435771.smushcdn.com/2435771/wp-content/uploads/2023/10/Ocean-View-5-Marbella-MDR-Luxury-Homes-1170x785.jpg?lossy=2&strip=1&webp=1", "https://b2435771.smushcdn.com/2435771/wp-content/uploads/2023/10/ocean_view_marbella-08-Ocean-View-TERRAZA-02-copy-scaled-1.jpg?lossy=2&strip=1&webp=1"],
      features: ["Beachfront", "Swimming Pool", "24/7 Security", "Gym"]
    ),
    Investment(
      id: "inv-002",
      title: "Downtown Commercial Complex",
      location: "Porthacourt, Porthacourt",
      description: "Modern commercial space in the heart of Austin's tech district. Ideal for offices and retail spaces.",
      realtorName: "Luxurious Paegent",
      realtorImage: "https://content.jdmagicbox.com/comp/guwahati/h9/9999px361.x361.240612125146.r6h9/catalogue/luxurious-pageant-pvt-ltd-ganeshguri-guwahati-estate-agents-for-residential-rental-e54qpm0gc5.jpg",
      minInvestment: 100000,
      expectedReturn: "10-13% annually",
      duration: "5-7 years",
      investors: 32,
      remainingAmount: 500000,
      totalAmount: 4000000,
      images: ["https://www.royalerealtorsindia.com/wp-content/uploads/2025/01/4.jpg", "https://geetanjalihomestate.co.in/mpanel/property-uploads/downtown-saroji-main-1738841974.webp"],
      features: ["Prime Location", "Modern Architecture", "Parking Space", "Green Building"]
    ),
    Investment(
      id: "inv-003",
      title: "Suburban Housing Development",
      location: "Abuja City, F.C.T",
      description: "New residential development in a rapidly growing suburb. Perfect for families with excellent school districts.",
      realtorName: "LandWey Invt. Ltd",
      realtorImage: "https://images.ctfassets.net/abyiu1tn7a0f/4fVwW5zVvNyFmuEs0oBC7Y/571261a1ec58b0c0f0af190e9580824f/landwey-logo.jpg",
      minInvestment: 75000,
      expectedReturn: "8-11% annually",
      duration: "4-6 years",
      investors: 26,
      remainingAmount: 350000,
      totalAmount: 1500000,
      images: ["https://www.ft.com/__origami/service/image/v2/images/raw/https%3A%2F%2Fd1e00ek4ebabms.cloudfront.net%2Fproduction%2F70d51010-e1df-462c-9a7f-694236de29a0.jpg?source=next-article&fit=scale-down&quality=highest&width=700&dpr=1", "https://assets.bwbx.io/images/users/iqjWHBFdfxIU/iUc_QUkWqdZg/v1/-1x-1.webp"],
      features: ["Family-Friendly", "Parks Nearby", "Good Schools", "Community Center"]
    )
  ];

  // Format price to Nigerian Naira
  String formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    ).format(price);
  }
  
  // Handle search
  void handleSearch(String query) {
    setState(() {
      searchQuery = query;
      
      if (query.trim().isEmpty) {
        filteredInvestments = investments;
        return;
      }
      
      filteredInvestments = investments.where((inv) => 
        inv.title.toLowerCase().contains(query.toLowerCase()) ||
        inv.location.toLowerCase().contains(query.toLowerCase()) ||
        inv.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  // Calculate profit based on investment amount
  void calculateProfit() {
    if (selectedInvestment == null || investmentAmount <= 0) {
      setState(() {
        calculatedProfit = null;
      });
      return;
    }

    // Parse the expected return percentage
    RegExp returnRegExp = RegExp(r'(\d+)-(\d+)');
    var returnMatch = returnRegExp.firstMatch(selectedInvestment!.expectedReturn);
    if (returnMatch == null) return;

    int minReturn = int.parse(returnMatch.group(1)!);
    int maxReturn = int.parse(returnMatch.group(2)!);
    
    // Calculate average return
    double avgReturn = (minReturn + maxReturn) / 2 / 100;
    
    // Extract duration
    RegExp durationRegExp = RegExp(r'(\d+)-(\d+)');
    var durationMatch = durationRegExp.firstMatch(selectedInvestment!.duration);
    if (durationMatch == null) return;
    
    double avgDuration = (int.parse(durationMatch.group(1)!) + int.parse(durationMatch.group(2)!)) / 2;
    
    // Calculate estimated profit (simple calculation)
    setState(() {
      calculatedProfit = investmentAmount * avgReturn * avgDuration;
    });
  }

  // Open calculator for a specific investment
  void openCalculator(Investment investment) {
    setState(() {
      selectedInvestment = investment;
      investmentAmount = investment.minInvestment;
      showCalculator = true;
      calculatedProfit = null;
    });
    showCalculatorDialog();
  }

  // Open details modal for a specific investment
  void openDetailsModal(Investment investment) {
    setState(() {
      selectedInvestment = investment;
      showDetailsModal = true;
      imageIndex = 0;
    });
    showDetailsBottomSheet();
  }

  // Navigate to next/previous image in details modal
  void nextImage() {
    if (selectedInvestment != null) {
      setState(() {
        imageIndex = (imageIndex == selectedInvestment!.images.length - 1) ? 0 : imageIndex + 1;
      });
    }
  }

  void prevImage() {
    if (selectedInvestment != null) {
      setState(() {
        imageIndex = (imageIndex == 0) ? selectedInvestment!.images.length - 1 : imageIndex - 1;
      });
    }
  }

  // Handle investment action
  void handleInvest() {
    if (selectedInvestment != null) {
      // Navigate to checkout page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: Center(child: Text('Checkout page for ${selectedInvestment!.title}')),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top search bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search interest rate of your choice",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                onChanged: handleSearch,
              ),
            ),
            
            // Vendor/Realtor button section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/investment-vendor-form');
                      },
                      icon: const Icon(Icons.business, color: Colors.white),
                      label: const Text(
                        'List Your Investment Opportunity',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // Title section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Invest in Real Estate",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Discover premium investment opportunities and grow your wealth",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Investment listings
                  ...filteredInvestments.map((investment) => buildInvestmentCard(investment)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar - Using the imported BottomNavigation widget
      bottomNavigationBar: SharedBottomNavigation(
        activeTab: "invest",
        onTabChange: (tab) {
          SharedBottomNavigation.handleNavigation(context, tab);
        },
      ),
    );
  }

  // Build investment card widget
  Widget buildInvestmentCard(Investment investment) {
    double progressPercentage = (investment.totalAmount - investment.remainingAmount) / investment.totalAmount;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with favorite button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  investment.images[0],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          
          // Investment info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and return rate
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.title,
                            style: const TextStyle(
                              fontSize: 18,
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
                              Text(
                                investment.location,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        investment.expectedReturn,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  investment.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Investment details
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '₦',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Min: ${formatPrice(investment.minInvestment)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            investment.duration,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${investment.investors} investors',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '₦${(investment.totalAmount - investment.remainingAmount).toString()} raised',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF39322),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => openDetailsModal(investment),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: const Color(0xFFF39322),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => openCalculator(investment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade600, side: BorderSide(color: Colors.blue.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Calculate Profit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Build calculator dialog
  void showCalculatorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profit Calculator', style: TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedInvestment != null) ...[
                        Text(
                          selectedInvestment!.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              selectedInvestment!.location,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Investment Amount (₦)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter amount',
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              investmentAmount = int.tryParse(value) ?? 0;
                            });
                          },
                          controller: TextEditingController(text: investmentAmount.toString()),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Minimum investment: ${formatPrice(selectedInvestment!.minInvestment)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expected Return:'),
                            Text(
                              selectedInvestment!.expectedReturn,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Investment Duration:'),
                            Text(
                              selectedInvestment!.duration,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setDialogState(() {
                                calculateProfit();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF39322),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Calculate Potential Profit'),
                          ),
                        ),
                        if (calculatedProfit != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Estimated total profit:',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatPrice(calculatedProfit!.round()),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This is an estimate based on average returns and may vary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show details bottom sheet
  void showDetailsBottomSheet() {
    if (selectedInvestment == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double progressPercentage = (selectedInvestment!.totalAmount - selectedInvestment!.remainingAmount) / 
                                       selectedInvestment!.totalAmount;
            
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header and close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedInvestment!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        // Image gallery
                        SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Image.network(
                                selectedInvestment!.images[imageIndex],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              
                              // Image counter
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${imageIndex + 1}/${selectedInvestment!.images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Image navigation
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.chevron_left),
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          prevImage();
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.chevron_right),
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          nextImage();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Location and investment details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedInvestment!.location,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Investment details
                              const Text(
                                'Investment Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Description
                              Text(
                                selectedInvestment!.description,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Features
                              const Text(
                                'Features',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedInvestment!.features.map((feature) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      feature,
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Investment stats
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Minimum Investment',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formatPrice(selectedInvestment!.minInvestment),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
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
                                                'Expected Return',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                selectedInvestment!.expectedReturn,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Duration',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                selectedInvestment!.duration,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
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
                                                'Current Investors',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${selectedInvestment!.investors}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
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
                              
                              const SizedBox(height: 24),
                              
                              // Funding progress
                              const Text(
                                'Funding Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Raised: ${formatPrice(selectedInvestment!.totalAmount - selectedInvestment!.remainingAmount)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Goal: ${formatPrice(selectedInvestment!.totalAmount)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progressPercentage,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFF39322),
                                      ),
                                      minHeight: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Remaining: ${formatPrice(selectedInvestment!.remainingAmount)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Realtor info
                              const Text(
                                'Managed By',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      selectedInvestment!.realtorImage,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedInvestment!.realtorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '4.8 (120 reviews)',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom action bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              openCalculator(selectedInvestment!);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade600, side: BorderSide(color: Colors.blue.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Calculate Profit'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              handleInvest();
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFFF39322),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Invest Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

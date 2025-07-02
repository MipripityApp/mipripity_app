import 'dart:math';
import 'package:flutter/material.dart';

/// Utility class for handling property prospect suggestions
class PropertyProspectUtil {
  /// Random number generator for picking suggestions
  static final Random _random = Random();
  
  /// Get a random set of suggestion bubbles for a specific property type
  /// Returns a list of PropertyProspect objects
  static List<PropertyProspect> getRandomSuggestionsForType(
    PropertyType type, 
    double propertyPrice,
  ) {
    // Get the appropriate suggestion set based on property type
    final List<PropertyProspect> suggestions = _getSuggestionsForType(type);
    
    // Shuffle the suggestions and take 8 of them
    final shuffled = List<PropertyProspect>.from(suggestions)..shuffle(_random);
    
    // Update price estimates based on the property price
    final result = shuffled.take(8).map((prospect) {
      return prospect.copyWithUpdatedCosts(propertyPrice);
    }).toList();
    
    return result;
  }
  
  /// Get the full suggestion set for a specific property type
  static List<PropertyProspect> _getSuggestionsForType(PropertyType type) {
    switch (type) {
      case PropertyType.residential:
        return _residentialSuggestions;
      case PropertyType.commercial:
        return _commercialSuggestions;
      case PropertyType.land:
        return _landSuggestions;
      case PropertyType.material:
        return _materialSuggestions;
    }
  }
  
  /// Show a modal with the suggestion details
  static void showProspectDetails(
    BuildContext context, 
    PropertyProspect prospect,
    double propertyPrice,
  ) {
    final updatedProspect = prospect.copyWithUpdatedCosts(propertyPrice);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          updatedProspect.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          updatedProspect.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Cost Estimates
                        const Text(
                          'Cost Estimates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Purchase Cost
                        _buildCostItem(
                          'Estimated Purchase Cost',
                          updatedProspect.purchaseCost,
                          const Color(0xFF000080),
                        ),
                        const SizedBox(height: 12),
                        
                        // Development Cost
                        _buildCostItem(
                          'Estimated Development Cost',
                          updatedProspect.developmentCost,
                          const Color(0xFFF39322),
                        ),
                        const SizedBox(height: 12),
                        
                        // Total Cost
                        _buildCostItem(
                          'Total Investment',
                          updatedProspect.purchaseCost + updatedProspect.developmentCost,
                          Colors.green[700]!,
                          isBold: true,
                        ),
                        const SizedBox(height: 30),
                        
                        // Tips
                        const Text(
                          'Realization Tips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        ...updatedProspect.realizationTips.map((tip) => _buildTipItem(tip)),
                        
                        const SizedBox(height: 30),
                        
                        // Contact Expert Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle contacting expert
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF000080),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Contact an Expert',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Build a cost item widget for the modal
  static Widget _buildCostItem(
    String label, 
    double amount, 
    Color color, {
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a tip item widget for the modal
  static Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFFF39322),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Format currency for display
  static String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    )}';
  }
  
  /// Residential Property Suggestions
  static final List<PropertyProspect> _residentialSuggestions = [
    PropertyProspect(
      title: 'Short Let Plan',
      description: 'Convert your property into a short-term rental for travelers and tourists. This option typically yields higher rental income than traditional long-term leases.',
      purchaseCostFactor: 1.0, // 100% of property price
      developmentCostFactor: 0.15, // 15% of property price for furnishing
      realizationTips: [
        'Furnish the property with quality furniture and appliances',
        'Install high-speed internet and smart home features',
        'Create a listing on platforms like Airbnb or Booking.com',
        'Consider hiring a property manager if you can\'t handle day-to-day operations',
        'Research local regulations regarding short-term rentals',
      ],
    ),
    PropertyProspect(
      title: 'Multi-Unit Rental',
      description: 'Convert a single-family property into multiple rental units to maximize rental income. This works best for larger properties with multiple rooms or floors.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.3, // 30% for conversion work
      realizationTips: [
        'Check zoning laws and obtain necessary permits for conversion',
        'Design efficient layouts that maximize the number of units',
        'Consider installing separate utilities for each unit',
        'Focus on soundproofing between units for tenant comfort',
        'Implement a secure access system for all tenants',
      ],
    ),
    PropertyProspect(
      title: 'Luxury Upgrade',
      description: 'Renovate the property to a luxury standard to attract high-income tenants or buyers. This strategy focuses on quality over quantity and targets premium market segments.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for luxury renovations
      realizationTips: [
        'Invest in high-end fixtures, appliances, and finishes',
        'Modernize bathrooms and kitchen with premium materials',
        'Add desirable amenities like a home office or entertainment space',
        'Consider smart home integration for lighting, security, and climate control',
        'Work with an interior designer to create a cohesive luxury aesthetic',
      ],
    ),
    PropertyProspect(
      title: 'Co-living Space',
      description: 'Transform the property into a co-living space where tenants have private bedrooms but share common areas. Popular among young professionals and students in urban areas.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.25, // 25% for conversion
      realizationTips: [
        'Design communal spaces that encourage interaction and community',
        'Create private bedrooms with high-quality soundproofing',
        'Implement a reliable system for managing shared utilities and services',
        'Consider including cleaning services in the rental package',
        'Establish clear house rules and conflict resolution processes',
      ],
    ),
    PropertyProspect(
      title: 'Home Office Conversion',
      description: 'Redesign the property to incorporate dedicated home office spaces, catering to the growing remote work trend. Attracts professionals seeking work-from-home friendly accommodations.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.2, // 20% for conversion
      realizationTips: [
        'Create ergonomic workspaces with proper lighting and ventilation',
        'Install high-speed internet infrastructure and backup power',
        'Soundproof office areas from living spaces for better concentration',
        'Consider including built-in desks and storage solutions',
        'Market specifically to remote workers and digital professionals',
      ],
    ),
    PropertyProspect(
      title: 'Student Housing',
      description: 'Convert the property to accommodate students from nearby educational institutions. This offers steady rental income with academic year cycles.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.18, // 18% for adaptation
      realizationTips: [
        'Optimize room layouts to maximize bed count while maintaining comfort',
        'Create study areas with good lighting and desk space',
        'Install robust wifi infrastructure throughout the property',
        'Use durable materials and fixtures that can withstand heavy use',
        'Consider offering inclusive packages with utilities and internet',
      ],
    ),
    PropertyProspect(
      title: 'Executive Rental',
      description: 'Position the property as an executive rental for corporate clients and relocating professionals seeking medium-term accommodation (3-12 months).',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.25, // 25% for upscale furnishing
      realizationTips: [
        'Furnish with high-quality, professional-looking furniture',
        'Create a dedicated home office space with ergonomic features',
        'Offer additional services like cleaning and maintenance',
        'Partner with local corporations for their employee housing needs',
        'Implement a secure and convenient check-in/check-out process',
      ],
    ),
    PropertyProspect(
      title: 'Serviced Apartment',
      description: 'Transform the property into a serviced apartment with hotel-like amenities and services. Targets both short and medium-term guests looking for a home-like feel with added convenience.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.35, // 35% for conversion and amenities
      realizationTips: [
        'Invest in high-quality furnishings and hotel-grade linens',
        'Set up a housekeeping service for regular cleaning',
        'Install a keyless entry system for convenient check-ins',
        'Consider offering additional services like laundry and groceries',
        'Develop a website and booking system for direct reservations',
      ],
    ),
    PropertyProspect(
      title: 'Multi-generational Home',
      description: 'Adapt the property to accommodate multiple generations of a family, with private areas for each generation and shared common spaces. Growing in popularity as housing costs rise.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.3, // 30% for adaptation
      realizationTips: [
        'Create separate entrances and private living areas if possible',
        'Design flexible spaces that can adapt to changing family needs',
        'Consider installing features for aging-in-place like grab bars',
        'Ensure adequate soundproofing between private areas',
        'Create generous common areas where the family can gather',
      ],
    ),
    PropertyProspect(
      title: 'Energy-Efficient Renovation',
      description: 'Upgrade the property with energy-efficient features to reduce operating costs and appeal to environmentally conscious tenants or buyers.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.25, // 25% for upgrades
      realizationTips: [
        'Install solar panels to reduce electricity costs',
        'Upgrade to energy-efficient windows and doors',
        'Add proper insulation to reduce heating and cooling costs',
        'Replace old appliances with energy-efficient models',
        'Consider a rainwater harvesting system for garden irrigation',
      ],
    ),
    PropertyProspect(
      title: 'Vacation Rental',
      description: 'Convert the property into a vacation rental in a tourist-friendly location. This option can provide higher returns during peak tourist seasons.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.2, // 20% for furnishing and decor
      realizationTips: [
        'Decorate with a theme that reflects the local culture or attractions',
        'Create Instagrammable spots within the property for social media appeal',
        'Provide a detailed local guide with recommendations for guests',
        'Consider seasonal pricing strategies to maximize revenue',
        'Partner with local tour operators and activity providers',
      ],
    ),
    PropertyProspect(
      title: 'Senior-Friendly Housing',
      description: 'Adapt the property to be accessible and comfortable for seniors, with safety features and easy maintenance. Addresses the growing demand for age-appropriate housing.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.22, // 22% for adaptations
      realizationTips: [
        'Install grab bars in bathrooms and stairways',
        'Ensure doorways are wide enough for walker or wheelchair access',
        'Create step-free entrances where possible',
        'Use slip-resistant flooring throughout the property',
        'Consider emergency call systems for added safety',
      ],
    ),
    PropertyProspect(
      title: 'Rent-to-Own Scheme',
      description: 'Offer the property on a rent-to-own basis, allowing tenants to purchase the property over time. This attracts tenants who aspire to homeownership but need time to build credit or save for a down payment.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.1, // 10% for property preparation
      realizationTips: [
        'Consult with a lawyer to draft a proper rent-to-own agreement',
        'Set a fair future purchase price in the initial contract',
        'Determine what portion of monthly rent will apply toward the purchase',
        'Establish clear timelines and conditions for the purchase option',
        'Consider requiring tenants to handle minor repairs during the rental period',
      ],
    ),
    PropertyProspect(
      title: 'Room-by-Room Rental',
      description: 'Rent out individual rooms rather than the entire property, which can generate higher total rental income. Popular in university areas and cities with high housing costs.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.15, // 15% for conversion
      realizationTips: [
        'Ensure each room has adequate privacy and security features',
        'Create clear house rules regarding common areas and quiet hours',
        'Consider installing individual locks on bedroom doors',
        'Establish a fair system for sharing utilities and common expenses',
        'Stagger lease agreements to avoid simultaneous vacancies',
      ],
    ),
    PropertyProspect(
      title: 'Premium Corporate Housing',
      description: 'Position the property as high-end corporate housing for executives and professionals on extended assignments. This niche offers higher rental rates and more stable tenants.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.3, // 30% for premium furnishing
      realizationTips: [
        'Furnish with high-quality, professional furniture and decor',
        'Provide premium appliances and electronics',
        'Offer a concierge service for additional amenities',
        'Develop relationships with local corporate HR departments',
        'Consider offering transportation services or parking solutions',
      ],
    ),
  ];
  
  /// Commercial Property Suggestions
  static final List<PropertyProspect> _commercialSuggestions = [
    PropertyProspect(
      title: 'Mini Mall Conversion',
      description: 'Transform the commercial property into a mini mall with multiple retail spaces. This maximizes rental income from a single property by accommodating several businesses.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for conversion
      realizationTips: [
        'Design flexible retail spaces that can be adjusted for different tenants',
        'Create a common area with seating and amenities',
        'Establish a tenant mix that offers complementary products/services',
        'Install clear signage and directory systems',
        'Consider implementing shared services like security and cleaning',
      ],
    ),
    PropertyProspect(
      title: 'Office Leasing',
      description: 'Convert the property into office spaces for lease to businesses and professionals. Can be structured as traditional offices or modern co-working spaces.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.35, // 35% for office setup
      realizationTips: [
        'Create a mix of private offices and shared workspaces',
        'Install robust IT infrastructure with high-speed internet',
        'Design comfortable meeting rooms and common areas',
        'Consider offering additional services like reception and mail handling',
        'Implement a secure access system for 24/7 operation',
      ],
    ),
    PropertyProspect(
      title: 'Event Center',
      description: 'Convert the property into an event center for hosting corporate events, weddings, conferences, and social gatherings. High potential returns for well-located properties.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.45, // 45% for conversion
      realizationTips: [
        'Design flexible spaces that can be configured for different events',
        'Install professional sound and lighting systems',
        'Create a dedicated catering area or kitchen',
        'Consider parking solutions for guests',
        'Develop relationships with event planners and catering companies',
      ],
    ),
    PropertyProspect(
      title: 'Restaurant Conversion',
      description: 'Transform the property into a restaurant or food establishment. Ideal for properties in high-traffic areas with good visibility.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.5, // 50% for restaurant setup
      realizationTips: [
        'Design a kitchen that meets local health and safety regulations',
        'Create an attractive dining area with appropriate lighting',
        'Consider outdoor seating options if possible',
        'Install proper ventilation and fire safety systems',
        'Develop a unique concept that stands out in the local market',
      ],
    ),
    PropertyProspect(
      title: 'Medical Facility',
      description: 'Convert the property into a medical facility such as a clinic, diagnostic center, or specialized healthcare practice. Offers stable returns in a growing sector.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.6, // 60% for medical conversion
      realizationTips: [
        'Design spaces that comply with healthcare facility regulations',
        'Install specialized plumbing and electrical systems as needed',
        'Create comfortable waiting areas and reception',
        'Ensure accessibility for patients with mobility challenges',
        'Consider soundproofing for patient privacy',
      ],
    ),
    PropertyProspect(
      title: 'Boutique Hotel',
      description: 'Transform the property into a small boutique hotel, offering unique accommodations with personalized service. Works well in tourist areas or business districts.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.7, // 70% for hotel conversion
      realizationTips: [
        'Create guest rooms with distinctive designs and amenities',
        'Develop common areas that reflect the hotel\'s theme or concept',
        'Implement a property management system for bookings',
        'Consider offering additional services like airport transfers',
        'Develop a strong brand identity and online presence',
      ],
    ),
    PropertyProspect(
      title: 'Educational Center',
      description: 'Convert the property into an educational center for tutoring, vocational training, or specialized courses. Serves growing demand for skills development and continuous education.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.3, // 30% for conversion
      realizationTips: [
        'Design classrooms with appropriate lighting and acoustics',
        'Create collaborative spaces for group projects',
        'Install educational technology infrastructure',
        'Consider soundproofing between teaching areas',
        'Develop partnerships with educational institutions or trainers',
      ],
    ),
    PropertyProspect(
      title: 'Fitness Center',
      description: 'Transform the property into a fitness center or gym. Can be positioned as a general fitness facility or specialized studio (yoga, CrossFit, etc.).',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for equipment and conversion
      realizationTips: [
        'Design spaces for different types of workouts',
        'Install proper flooring suitable for exercise activities',
        'Consider shower and changing facilities',
        'Implement good ventilation and climate control',
        'Create a membership model that ensures recurring revenue',
      ],
    ),
    PropertyProspect(
      title: 'Storage Facility',
      description: 'Convert the property into a self-storage facility, offering secure storage units of various sizes. Requires minimal staffing and offers steady income.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.25, // 25% for conversion
      realizationTips: [
        'Design a mix of storage unit sizes to meet different needs',
        'Implement a secure access system for tenants',
        'Install surveillance cameras and good lighting',
        'Consider climate-controlled units for sensitive items',
        'Develop an efficient system for unit rentals and billing',
      ],
    ),
    PropertyProspect(
      title: 'Tech Hub',
      description: 'Create a specialized workspace for technology startups and digital businesses, with high-speed internet and collaborative areas. Attracts innovative companies and professionals.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.45, // 45% for tech infrastructure
      realizationTips: [
        'Install enterprise-grade internet infrastructure',
        'Create a mix of private offices and open collaboration spaces',
        'Design meeting rooms with video conferencing capabilities',
        'Consider 24/7 access with secure entry systems',
        'Offer additional services like technical support or mentorship',
      ],
    ),
    PropertyProspect(
      title: 'Entertainment Venue',
      description: 'Transform the property into an entertainment venue such as a comedy club, small theater, or gaming center. Creates a destination that can generate revenue from tickets and concessions.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.55, // 55% for specialized equipment
      realizationTips: [
        'Design the space with good sightlines and acoustics',
        'Install appropriate lighting and sound systems',
        'Create a welcoming lobby and concession area',
        'Consider soundproofing to prevent noise complaints',
        'Develop a programming calendar with regular events',
      ],
    ),
    PropertyProspect(
      title: 'Artisan Marketplace',
      description: 'Create a marketplace for local artisans and craftspeople to sell their products. Combines retail with an experiential shopping environment that attracts customers.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.3, // 30% for conversion
      realizationTips: [
        'Design flexible booth or stall spaces for vendors',
        'Create an attractive common area that encourages browsing',
        'Consider demonstration areas where artisans can show their craft',
        'Implement good signage and navigation throughout the space',
        'Develop a curated approach to vendor selection for quality control',
      ],
    ),
    PropertyProspect(
      title: 'Specialized Retail Concept',
      description: 'Develop a unique retail concept store that offers a distinctive shopping experience. Focus on creating an immersive environment that attracts customers looking for something different.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for specialized design
      realizationTips: [
        'Develop a strong, unique concept that stands out in the market',
        'Design the interior to reflect and enhance the concept',
        'Create areas for product demonstrations or interactive experiences',
        'Consider how to incorporate digital elements into the physical store',
        'Develop a strong brand identity and marketing strategy',
      ],
    ),
    PropertyProspect(
      title: 'Professional Services Hub',
      description: 'Create a center for professional service providers such as lawyers, accountants, consultants, and financial advisors. Offers a prestigious address with shared amenities.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.35, // 35% for professional environment
      realizationTips: [
        'Design elegant private offices and meeting spaces',
        'Create a professional reception area for clients',
        'Implement sound privacy solutions for confidential discussions',
        'Consider offering administrative support services',
        'Develop a tenant mix of complementary but non-competing services',
      ],
    ),
    PropertyProspect(
      title: 'Mixed-Use Development',
      description: 'Transform the property into a mixed-use space combining commercial, retail, and possibly residential elements. Creates a dynamic environment with multiple revenue streams.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.5, // 50% for complex conversion
      realizationTips: [
        'Design the layout to create natural flow between different uses',
        'Consider separate entrances for different components',
        'Implement appropriate sound isolation between areas',
        'Create shared amenities that benefit all users of the space',
        'Develop a management plan that addresses the needs of diverse tenants',
      ],
    ),
  ];
  
  /// Land Property Suggestions
  static final List<PropertyProspect> _landSuggestions = [
    PropertyProspect(
      title: 'Housing Development',
      description: 'Develop the land into a housing estate with multiple residential units. This can range from affordable housing to luxury villas depending on the location and market demand.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 2.0, // 200% of land price for development
      realizationTips: [
        'Conduct a thorough market analysis to determine the optimal housing type',
        'Obtain all necessary permits and approvals before beginning construction',
        'Consider phased development to manage cash flow',
        'Invest in quality infrastructure like roads and drainage',
        'Develop a marketing strategy targeting your ideal buyers',
      ],
    ),
    PropertyProspect(
      title: 'Farming Lease',
      description: 'Lease the land to farmers for agricultural purposes. This provides steady income with minimal development costs and maintains the land\'s value for future development.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.1, // 10% for basic infrastructure
      realizationTips: [
        'Assess the soil quality and water access for agricultural suitability',
        'Consider dividing larger plots into smaller leases for multiple farmers',
        'Develop clear lease agreements with terms for land maintenance',
        'Research agricultural subsidies that might be available',
        'Consider organic farming which may command premium lease rates',
      ],
    ),
    PropertyProspect(
      title: 'Commercial Complex',
      description: 'Develop a commercial complex with retail spaces, offices, or mixed-use buildings. Ideal for land in growing urban or suburban areas with good access.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 2.5, // 250% for commercial development
      realizationTips: [
        'Conduct a thorough traffic and accessibility analysis',
        'Design with flexibility to accommodate different types of businesses',
        'Consider including amenities that will attract quality tenants',
        'Develop a phased construction approach if cash flow is a concern',
        'Create a professional property management plan for ongoing operations',
      ],
    ),
    PropertyProspect(
      title: 'Recreational Park',
      description: 'Develop the land into a recreational park with paid activities. Options include adventure parks, water parks, sports facilities, or family entertainment centers.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 1.8, // 180% for recreational development
      realizationTips: [
        'Research the recreational needs and preferences in the local market',
        'Design activities that appeal to multiple age groups',
        'Consider seasonal factors in your business model',
        'Invest in safety features and appropriate insurance',
        'Develop marketing strategies for different customer segments',
      ],
    ),
    PropertyProspect(
      title: 'Educational Institution',
      description: 'Develop the land for educational purposes such as a school, college, or training center. Education is a growing sector with stable long-term prospects.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 2.2, // 220% for educational facilities
      realizationTips: [
        'Research educational needs in the area and identify gaps',
        'Consider partnering with established educational operators',
        'Design facilities that meet educational standards and regulations',
        'Plan for future expansion in your initial design',
        'Develop relationships with educational authorities and accreditation bodies',
      ],
    ),
    PropertyProspect(
      title: 'Storage Facility',
      description: 'Develop a self-storage facility on the land. These facilities require relatively low maintenance and can provide steady income in urban and suburban areas.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 1.2, // 120% for storage units
      realizationTips: [
        'Research local demand for storage and competitor pricing',
        'Design a mix of unit sizes to meet various needs',
        'Implement security features like surveillance and controlled access',
        'Consider climate-controlled units for higher rental rates',
        'Develop an efficient management system for rentals and payments',
      ],
    ),
    PropertyProspect(
      title: 'Renewable Energy Farm',
      description: 'Use the land for renewable energy generation such as solar or wind farms. This can provide long-term income through power purchase agreements with utility companies.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 1.5, // 150% for energy infrastructure
      realizationTips: [
        'Assess the land\'s suitability for solar or wind energy generation',
        'Research government incentives for renewable energy projects',
        'Explore options for connecting to the power grid',
        'Consider partnership with experienced renewable energy developers',
        'Understand the long-term maintenance requirements and costs',
      ],
    ),
    PropertyProspect(
      title: 'Hospitality Development',
      description: 'Develop a hospitality project such as a hotel, resort, or guest houses. Ideal for scenic locations or areas with tourist or business traveler potential.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 2.8, // 280% for hospitality development
      realizationTips: [
        'Conduct a thorough market analysis of tourism or business travel in the area',
        'Consider partnering with established hotel operators',
        'Design facilities that highlight the location\'s unique features',
        'Develop amenities that will attract your target guest demographic',
        'Create a comprehensive marketing strategy for reaching potential guests',
      ],
    ),
    PropertyProspect(
      title: 'Industrial Park',
      description: 'Develop the land into an industrial park with facilities for manufacturing, warehousing, or logistics. Growing e-commerce creates demand for such facilities.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 1.7, // 170% for industrial development
      realizationTips: [
        'Ensure the location has good transportation access',
        'Design flexible spaces that can accommodate different industries',
        'Invest in robust infrastructure like power supply and internet',
        'Consider environmental factors and compliance requirements',
        'Develop relationships with industrial brokers and economic development agencies',
      ],
    ),
    PropertyProspect(
      title: 'Residential Land Subdivision',
      description: 'Subdivide the land into smaller plots for individual home construction. This strategy can provide quicker returns with less development investment.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.6, // 60% for subdivision and infrastructure
      realizationTips: [
        'Research zoning regulations and minimum lot size requirements',
        'Invest in quality infrastructure that will attract premium buyers',
        'Consider creating design guidelines for a cohesive neighborhood',
        'Develop a marketing strategy targeting individual home builders',
        'Plan phased development if dealing with a large parcel',
      ],
    ),
    PropertyProspect(
      title: 'Mixed-Use Development',
      description: 'Create a development combining residential, commercial, and possibly recreational elements. This diversified approach can reduce risk and create a vibrant community.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 2.3, // 230% for mixed development
      realizationTips: [
        'Design with integration in mind to create a cohesive community',
        'Focus on creating public spaces that enhance the overall experience',
        'Consider transportation and parking needs for different uses',
        'Plan the tenant mix carefully for commercial spaces',
        'Develop a comprehensive management plan for the completed project',
      ],
    ),
    PropertyProspect(
      title: 'Religious Center',
      description: 'Develop the land into a religious center such as a church, mosque, or multi-faith facility. Religious organizations often have stable, community-based funding.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 1.6, // 160% for development
      realizationTips: [
        'Research the religious demographic of the area',
        'Consider designing multi-purpose spaces for various activities',
        'Include adequate parking and access routes',
        'Plan for future expansion possibilities',
        'Develop relationships with religious organizations seeking facilities',
      ],
    ),
    PropertyProspect(
      title: 'Event Venue',
      description: 'Develop an outdoor event venue for weddings, concerts, and corporate events. Requires less building infrastructure while utilizing the natural landscape.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 1.0, // 100% for basic infrastructure
      realizationTips: [
        'Preserve and enhance natural features that make the venue unique',
        'Develop basic infrastructure like access roads and utilities',
        'Create flexible spaces that can accommodate different types of events',
        'Consider weather contingency plans for outdoor venues',
        'Build relationships with event planners and catering companies',
      ],
    ),
    PropertyProspect(
      title: 'Healthcare Facility',
      description: 'Develop a healthcare facility such as a hospital, clinic, or specialized care center. Healthcare is a growing sector with stable long-term demand.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 2.5, // 250% for healthcare development
      realizationTips: [
        'Research healthcare needs in the area to identify gaps',
        'Consider partnering with established healthcare providers',
        'Design facilities that meet healthcare regulations and standards',
        'Plan for future technological upgrades and expansion',
        'Develop relationships with healthcare networks and insurance providers',
      ],
    ),
    PropertyProspect(
      title: 'Timber Investment',
      description: 'Plant timber-yielding trees for long-term investment. This sustainable approach can provide returns through selective harvesting while maintaining the land\'s value.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for planting and management
      realizationTips: [
        'Select tree species suitable for the climate and soil conditions',
        'Develop a long-term forest management plan',
        'Consider certification for sustainable forestry practices',
        'Research tax incentives for timber investments',
        'Plan for periodic income through selective harvesting',
      ],
    ),
  ];
  
  /// Material Property Suggestions
  static final List<PropertyProspect> _materialSuggestions = [
    PropertyProspect(
      title: 'Wholesale Sale',
      description: 'Purchase materials in bulk and sell them to retailers or contractors at wholesale prices. This approach leverages volume purchasing for profit margin.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.2, // 20% for logistics and marketing
      realizationTips: [
        'Develop relationships with multiple reliable suppliers',
        'Create efficient inventory management and storage systems',
        'Build a network of regular buyers in the construction industry',
        'Consider offering delivery services for larger orders',
        'Implement a customer relationship management system',
      ],
    ),
    PropertyProspect(
      title: 'Bulk Supply Link',
      description: 'Act as an intermediary between manufacturers and large-scale construction projects. This business model focuses on securing and fulfilling large material orders.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.15, // 15% for business setup
      realizationTips: [
        'Build strong relationships with manufacturers for preferential pricing',
        'Develop a network of contacts in construction and development',
        'Create a system for efficiently managing large orders',
        'Consider specializing in specific types of construction materials',
        'Invest in reliable logistics partners for timely deliveries',
      ],
    ),
    PropertyProspect(
      title: 'Retail Distribution',
      description: 'Establish a retail outlet selling building materials to individual consumers and small contractors. This approach taps into the home improvement and DIY markets.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for retail setup
      realizationTips: [
        'Choose a location with good accessibility for customers',
        'Design the store layout for easy browsing and product discovery',
        'Train staff to provide knowledgeable advice to DIY customers',
        'Consider offering complementary services like tool rental',
        'Develop weekend workshops to attract and educate customers',
      ],
    ),
    PropertyProspect(
      title: 'Processing & Value Addition',
      description: 'Set up a facility to process raw materials into higher-value products. For example, converting timber into furniture components or stone into decorative tiles.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.7, // 70% for processing equipment
      realizationTips: [
        'Identify products with strong market demand and healthy margins',
        'Invest in quality processing equipment for consistent output',
        'Develop quality control procedures to maintain standards',
        'Train skilled operators for specialized processing equipment',
        'Consider creating a branded product line for better recognition',
      ],
    ),
    PropertyProspect(
      title: 'Import Substitution',
      description: 'Identify commonly imported building materials and produce local alternatives. This strategy can be attractive in markets with high import costs or unreliable supply chains.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.6, // 60% for production setup
      realizationTips: [
        'Research materials with high import costs or supply issues',
        'Ensure your alternative products meet industry standards',
        'Highlight the benefits of local sourcing in your marketing',
        'Develop relationships with contractors and developers',
        'Consider partnering with relevant trade associations',
      ],
    ),
    PropertyProspect(
      title: 'Equipment Rental',
      description: 'Establish a construction equipment rental business alongside material sales. This complementary service can provide additional revenue streams and attract contractor customers.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.8, // 80% for equipment inventory
      realizationTips: [
        'Invest in durable, high-demand equipment with good ROI',
        'Develop clear rental agreements and deposit policies',
        'Implement a maintenance schedule to keep equipment reliable',
        'Consider offering operator training for complex equipment',
        'Explore insurance options to protect your investment',
      ],
    ),
    PropertyProspect(
      title: 'Specialized Materials Provider',
      description: 'Focus on niche or specialized building materials that are not widely available. This strategy can command premium prices and establish your business as a go-to specialist.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.5, // 50% for specialized inventory
      realizationTips: [
        'Research emerging trends in construction materials',
        'Become knowledgeable about your specialized products',
        'Develop relationships with architects and designers who specify materials',
        'Create educational content about your specialized products',
        'Consider offering consultation services alongside material sales',
      ],
    ),
    PropertyProspect(
      title: 'Export Business',
      description: 'Develop an export business for locally abundant building materials. This approach taps into international markets where these materials may be scarce or in high demand.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for export operations
      realizationTips: [
        'Research international markets with demand for your materials',
        'Understand export regulations and documentation requirements',
        'Develop relationships with international buyers or agents',
        'Consider obtaining relevant certifications for target markets',
        'Create efficient packaging for international shipping',
      ],
    ),
    PropertyProspect(
      title: 'Green Building Materials',
      description: 'Specialize in environmentally friendly and sustainable building materials. This growing sector appeals to eco-conscious consumers and projects seeking green building certifications.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.5, // 50% for green inventory
      realizationTips: [
        'Research materials with legitimate environmental benefits',
        'Obtain relevant eco-certifications for your products',
        'Educate customers about the benefits of sustainable materials',
        'Connect with architects and builders focused on green construction',
        'Consider creating demonstration areas showing materials in use',
      ],
    ),
    PropertyProspect(
      title: 'Material Recycling',
      description: 'Establish a business recycling construction waste into usable materials. This approach combines environmental benefits with potential cost advantages.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.6, // 60% for recycling equipment
      realizationTips: [
        'Research recycling processes for different construction materials',
        'Develop relationships with construction sites for waste collection',
        'Invest in appropriate processing equipment for your target materials',
        'Ensure recycled products meet quality standards for their intended use',
        'Highlight the environmental benefits in your marketing',
      ],
    ),
    PropertyProspect(
      title: 'Custom Fabrication',
      description: 'Offer custom fabrication services for building materials such as metalwork, millwork, or stonework. This value-added service can command premium prices for bespoke products.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.7, // 70% for fabrication setup
      realizationTips: [
        'Invest in skilled craftspeople and quality equipment',
        'Develop a portfolio showcasing your custom work',
        'Build relationships with architects and interior designers',
        'Create a clear process for custom orders from concept to completion',
        'Consider offering design services alongside fabrication',
      ],
    ),
    PropertyProspect(
      title: 'Educational Resource',
      description: 'Develop a training center or educational resource alongside material sales. This approach positions your business as an expert and builds customer loyalty.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.3, // 30% for educational setup
      realizationTips: [
        'Create hands-on workshops for DIY enthusiasts',
        'Develop training programs for professional builders',
        'Consider certification courses for specialized materials',
        'Create instructional content like videos and guides',
        'Build relationships with trade schools and apprenticeship programs',
      ],
    ),
    PropertyProspect(
      title: 'Online Marketplace',
      description: 'Create an online platform connecting material suppliers with buyers. This digital approach can scale beyond physical inventory limitations.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.4, // 40% for platform development
      realizationTips: [
        'Invest in a user-friendly website and mobile app',
        'Develop a secure payment and order management system',
        'Create a vetting process for suppliers on your platform',
        'Consider logistics partnerships for efficient delivery',
        'Implement a review system to build trust among users',
      ],
    ),
    PropertyProspect(
      title: 'Material Testing Laboratory',
      description: 'Establish a testing facility for building materials. This service ensures materials meet required standards and can be particularly valuable in markets with quality concerns.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.8, // 80% for testing equipment
      realizationTips: [
        'Invest in precision testing equipment for relevant materials',
        'Hire qualified technicians with appropriate certifications',
        'Seek accreditation from relevant standards organizations',
        'Develop relationships with construction companies and developers',
        'Consider offering consultation services based on testing results',
      ],
    ),
    PropertyProspect(
      title: 'Kit Home Development',
      description: 'Use materials to develop pre-fabricated or kit homes. This approach combines materials supply with architectural design for a complete housing solution.',
      purchaseCostFactor: 1.0,
      developmentCostFactor: 0.9, // 90% for design and manufacturing
      realizationTips: [
        'Develop standardized designs with customization options',
        'Create efficient manufacturing processes for components',
        'Build relationships with contractors for assembly services',
        'Consider offering financing options for complete packages',
        'Create display models for customers to experience the product',
      ],
    ),
  ];
}

/// Property type enum for categorizing properties
enum PropertyType {
  residential,
  commercial,
  land,
  material,
}

/// Class representing a property prospect suggestion
class PropertyProspect {
  final String title;
  final String description;
  final double purchaseCostFactor;
  final double developmentCostFactor;
  final List<String> realizationTips;
  final double purchaseCost;
  final double developmentCost;
  
  PropertyProspect({
    required this.title,
    required this.description,
    required this.purchaseCostFactor,
    required this.developmentCostFactor,
    required this.realizationTips,
    this.purchaseCost = 0,
    this.developmentCost = 0,
  });
  
  /// Create a copy with updated cost values based on the property price
  PropertyProspect copyWithUpdatedCosts(double propertyPrice) {
    return PropertyProspect(
      title: title,
      description: description,
      purchaseCostFactor: purchaseCostFactor,
      developmentCostFactor: developmentCostFactor,
      realizationTips: realizationTips,
      purchaseCost: propertyPrice * purchaseCostFactor,
      developmentCost: propertyPrice * developmentCostFactor,
    );
  }
}
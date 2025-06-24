import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Data models for filter options
class StateWithLGAs {
  final String state;
  final List<String> lgas;

  StateWithLGAs({required this.state, required this.lgas});
}

class MaterialQuantityOption {
  final String type;
  final List<String> quantityOptions;

  MaterialQuantityOption({required this.type, required this.quantityOptions});
}

class FilterForm extends StatefulWidget {
  final String selectedCategory;
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onFilterApplied;
  final VoidCallback onClose;

  const FilterForm({
    Key? key,
    required this.selectedCategory,
    this.initialFilters = const {},
    required this.onFilterApplied,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Filter values
  late Map<String, dynamic> _filterValues;
  
  // Selected state for LGA filtering
  String? _selectedState;
  
  // Material type for dynamic quantity options
  String? _selectedMaterialType;

  // Lists of filter options
  final List<StateWithLGAs> _statesWithLGAs = [
    StateWithLGAs(
      state: 'Lagos',
      lgas: ['Alimosho', 'Ajeromi-Ifelodun', 'Kosofe', 'Mushin', 'Oshodi-Isolo', 'Ojo', 'Ikorodu', 'Surulere', 'Agege', 'Ifako-Ijaiye', 'Shomolu', 'Amuwo-Odofin', 'Lagos Mainland', 'Ikeja', 'Eti-Osa', 'Badagry', 'Apapa', 'Lagos Island', 'Epe', 'Ibeju-Lekki'],
    ),
    StateWithLGAs(
      state: 'Oyo',
      lgas: ['Akinyele', 'Afijio', 'Egbeda', 'Ibadan North', 'Ibadan North-East', 'Ibadan North-West', 'Ibadan South-East', 'Ibadan South-West', 'Ibarapa Central', 'Ibarapa East', 'Ibarapa North', 'Ido', 'Irepo', 'Iseyin', 'Itesiwaju', 'Iwajowa', 'Kajola', 'Lagelu', 'Ogbomosho North', 'Ogbomosho South'],
    ),
    StateWithLGAs(
      state: 'Ogun',
      lgas: ['Abeokuta North', 'Abeokuta South', 'Ado-Odo/Ota', 'Egbado North', 'Egbado South', 'Ewekoro', 'Ifo', 'Ijebu East', 'Ijebu North', 'Ijebu North East', 'Ijebu Ode', 'Ikenne', 'Imeko Afon', 'Ipokia', 'Obafemi Owode', 'Odeda', 'Odogbolu', 'Ogun Waterside', 'Remo North', 'Shagamu'],
    ),
    StateWithLGAs(
      state: 'Imo',
      lgas: ['Aboh Mbaise', 'Ahiazu Mbaise', 'Ehime Mbano', 'Ezinihitte', 'Ideato North', 'Ideato South', 'Ihitte/Uboma', 'Ikeduru', 'Isiala Mbano', 'Isu', 'Mbaitoli', 'Ngor Okpala', 'Njaba', 'Nkwerre', 'Nwangele', 'Obowo', 'Oguta', 'Ohaji/Egbema', 'Okigwe', 'Orlu'],
    ),
    StateWithLGAs(
      state: 'Rivers',
      lgas: ['Abua/Odual', 'Ahoada East', 'Ahoada West', 'Akuku-Toru', 'Andoni', 'Asari-Toru', 'Bonny', 'Degema', 'Eleme', 'Emuoha', 'Etche', 'Gokana', 'Ikwerre', 'Khana', 'Obio/Akpor', 'Ogba/Egbema/Ndoni', 'Ogu/Bolo', 'Okrika', 'Omuma', 'Opobo/Nkoro', 'Oyigbo', 'Port Harcourt', 'Tai'],
    ),
    StateWithLGAs(
      state: 'Abuja',
      lgas: ['Abaji', 'Bwari', 'Gwagwalada', 'Kuje', 'Kwali', 'Municipal Area Council'],
    ),
    StateWithLGAs(
      state: 'Cross River',
      lgas: ['Abi', 'Akamkpa', 'Akpabuyo', 'Bakassi', 'Bekwarra', 'Biase', 'Boki', 'Calabar Municipal', 'Calabar South', 'Etung', 'Ikom', 'Obanliku', 'Obubra', 'Obudu', 'Odukpani', 'Ogoja', 'Yakuur', 'Yala'],
    ),
    StateWithLGAs(
      state: 'Kano',
      lgas: ['Ajingi', 'Albasu', 'Bagwai', 'Bebeji', 'Bichi', 'Bunkure', 'Dala', 'Dambatta', 'Dawakin Kudu', 'Dawakin Tofa', 'Doguwa', 'Fagge', 'Gabasawa', 'Garko', 'Garun Mallam', 'Gaya', 'Gezawa', 'Gwale', 'Gwarzo', 'Kabo', 'Kano Municipal', 'Karaye', 'Kibiya', 'Kiru', 'Kumbotso', 'Kunchi', 'Kura', 'Madobi', 'Makoda', 'Minjibir', 'Nasarawa', 'Rano', 'Rimin Gado', 'Rogo', 'Shanono', 'Sumaila', 'Takai', 'Tarauni', 'Tofa', 'Tsanyawa', 'Tudun Wada', 'Ungogo', 'Warawa', 'Wudil'],
    ),
  ];

  final List<String> _residentialTypes = [
    'Duplex', 'Story Building', 'Air BnB', 'Co-Living Space', 'Studio Apartment', 
    'Serviced Apartment', 'Single Room', 'Garden Apartment', 'Luxury Apartment', 
    'Cottage', '2 Bedroom Flat', 'Loft Apartment', 'Farm House', 
    'Condominium', 'Room & Parlor', 'Vacation Home', 'Town House', 
    '3 Bedroom Flat', '1 Room Self Contain', 'Pent House', 
    'Bungalow Single Room', '4 Bedroom Flat', 'Estate', 
    'Bungalow Flat', 'Block of Flat', 'Villa', 'Mini Flat'
  ];

  final List<String> _commercialTypes = [
    'Air BnB', 'Warehouse', 'Event Centre', 'Retail Store', 'Hotel', 'Hub', 'Mall', 'Office', 'Company', 'Business', 'Shortlet', 'Self Storage Facility'
  ];

  final List<String> _landTypes = [
    'Hectare', 'Acre', 'Plot'
  ];

  final List<String> _landQuantities = [
    'Above 100', 'Above 50', 'Above 10', '5', 'Less than 5', 'Less than 1'
  ];

  final List<String> _materialTypes = [
    'Chair', 'Table', 'Bath Tub', 'Mirror', 'Sofa', 'A.C', 
    'Television', 'Speaker', 'Fan', 'Curtain', 'Window', 
    'Iron', 'Tiles', 'Clock', 'Door', 'Fence wire', 
    'Paint', 'Art work', 'Artifact', 'Cement', 'Sand', 
    'Tank', 'Gate', 'Console'
  ];

  final List<MaterialQuantityOption> _materialQuantityOptions = [
    MaterialQuantityOption(
      type: 'Chair',
      quantityOptions: ['1-5', '6-10', '11-20', '21-50', 'Above 50'],
    ),
    MaterialQuantityOption(
      type: 'Table',
      quantityOptions: ['1-5', '6-10', '11-20', '21-50', 'Above 50'],
    ),
    MaterialQuantityOption(
      type: 'Bath Tub',
      quantityOptions: ['1', '2-5', '6-10', 'Above 10'],
    ),
    MaterialQuantityOption(
      type: 'Mirror',
      quantityOptions: ['1-5', '6-10', '11-20', 'Above 20'],
    ),
    MaterialQuantityOption(
      type: 'Sofa',
      quantityOptions: ['1 Set', '2-3 Sets', '4-5 Sets', 'Above 5 Sets'],
    ),
    MaterialQuantityOption(
      type: 'A.C',
      quantityOptions: ['1', '2-5', '6-10', 'Above 10'],
    ),
    MaterialQuantityOption(
      type: 'Television',
      quantityOptions: ['1', '2-5', '6-10', 'Above 10'],
    ),
    MaterialQuantityOption(
      type: 'Speaker',
      quantityOptions: ['1 Set', '2-3 Sets', '4-5 Sets', 'Above 5 Sets'],
    ),
    MaterialQuantityOption(
      type: 'Fan',
      quantityOptions: ['1-5', '6-10', '11-20', 'Above 20'],
    ),
    MaterialQuantityOption(
      type: 'Curtain',
      quantityOptions: ['1-5 Sets', '6-10 Sets', '11-20 Sets', 'Above 20 Sets'],
    ),
    MaterialQuantityOption(
      type: 'Window',
      quantityOptions: ['1-5', '6-10', '11-20', 'Above 20'],
    ),
    MaterialQuantityOption(
      type: 'Iron',
      quantityOptions: ['1-5', '6-10', '11-20', 'Above 20'],
    ),
    MaterialQuantityOption(
      type: 'Tiles',
      quantityOptions: ['1-10 Cartons', '11-50 Cartons', '51-100 Cartons', 'Above 100 Cartons'],
    ),
    MaterialQuantityOption(
      type: 'Clock',
      quantityOptions: ['1-5', '6-10', '11-20', 'Above 20'],
    ),
    MaterialQuantityOption(
      type: 'Door',
      quantityOptions: ['1-5', '6-10', '11-20', 'Above 20'],
    ),
    MaterialQuantityOption(
      type: 'Fence wire',
      quantityOptions: ['1-5 Rolls', '6-10 Rolls', '11-20 Rolls', 'Above 20 Rolls'],
    ),
    MaterialQuantityOption(
      type: 'Paint',
      quantityOptions: ['1-5 Buckets', '6-10 Buckets', '11-20 Buckets', 'Above 20 Buckets'],
    ),
    MaterialQuantityOption(
      type: 'Art work',
      quantityOptions: ['1-5 Pieces', '6-10 Pieces', '11-20 Pieces', 'Above 20 Pieces'],
    ),
    MaterialQuantityOption(
      type: 'Artifact',
      quantityOptions: ['1-5 Pieces', '6-10 Pieces', '11-20 Pieces', 'Above 20 Pieces'],
    ),
    MaterialQuantityOption(
      type: 'Cement',
      quantityOptions: ['1-10 Bags', '11-50 Bags', '51-100 Bags', 'Above 100 Bags'],
    ),
    MaterialQuantityOption(
      type: 'Sand',
      quantityOptions: ['1-5 Tons', '6-10 Tons', '11-20 Tons', 'Above 20 Tons'],
    ),
    MaterialQuantityOption(
      type: 'Tank',
      quantityOptions: ['1', '2-3', '4-5', 'Above 5'],
    ),
    MaterialQuantityOption(
      type: 'Gate',
      quantityOptions: ['1', '2-3', '4-5', 'Above 5'],
    ),
    MaterialQuantityOption(
      type: 'Console',
      quantityOptions: ['1', '2-3', '4-5', 'Above 5'],
    ),
  ];

  final List<String> _statusOptions = [
    'Available',
    'Sold', 
    'Under Contract',
    'Pending',
    'Off Market',
    'Coming Soon',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize filter values with initial filters
    _filterValues = Map<String, dynamic>.from(widget.initialFilters);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _animationController.forward();
    
    // Add haptic feedback when form appears
    HapticFeedback.mediumImpact();
    
    // Initialize selected state if location is in initial filters
    if (_filterValues.containsKey('state')) {
      _selectedState = _filterValues['state'];
    }
    
    // Initialize selected material type if type is in initial filters
    if (widget.selectedCategory == 'material' && _filterValues.containsKey('type')) {
      _selectedMaterialType = _filterValues['type'];
    }
    
    // Set price range from initial filters
    if (_filterValues.containsKey('minPrice') && _filterValues.containsKey('maxPrice')) {
      // Price range is already set
    } else if (_filterValues.containsKey('maxPrice')) {
      // Only max price is set (from budget input)
      _filterValues['minPrice'] = 0.0;
    } else {
      // Set default price range based on category
      switch (widget.selectedCategory) {
        case 'residential':
        case 'commercial':
        case 'land':
          _filterValues['minPrice'] = 0.0;
          _filterValues['maxPrice'] = 100000000.0;
          break;
        case 'material':
          _filterValues['minPrice'] = 0.0;
          _filterValues['maxPrice'] = 1000000.0;
          break;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get quantity options based on selected material type
  List<String> _getQuantityOptionsForMaterial(String materialType) {
    final option = _materialQuantityOptions.firstWhere(
      (option) => option.type == materialType,
      orElse: () => MaterialQuantityOption(
        type: materialType,
        quantityOptions: ['1', '2-5', '6-10', 'Above 10'],
      ),
    );
    
    return option.quantityOptions;
  }

  // Apply filters and close the form
  void _applyFilters() {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Add category to filter values
    _filterValues['category'] = widget.selectedCategory;
    
    widget.onFilterApplied(_filterValues);
    _closeForm();
  }

  // Close the form with animation
  void _closeForm() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  // Update filter value
  void _updateFilter(String key, dynamic value) {
    setState(() {
      if (value == null || (value is String && value.isEmpty)) {
        _filterValues.remove(key);
      } else {
        _filterValues[key] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _animation.value),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF000080),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter ${widget.selectedCategory.substring(0, 1).toUpperCase()}${widget.selectedCategory.substring(1)} Properties',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _closeForm,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Form content in a scrollable container
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Budget display if set
                      if (_filterValues.containsKey('maxPrice') && 
                          _filterValues['maxPrice'] != null &&
                          _filterValues['maxPrice'] > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF000080).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFF000080),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Confirm Your Budget',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF000080),
                                      ),
                                    ),
                                    Text(
                                      '₦${_formatPrice(_filterValues['maxPrice'])}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF39322),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF000080),
                                  size: 18,
                                ),
                                onPressed: () {
                                  // Allow editing the budget
                                  _showBudgetEditDialog();
                                },
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // General fields for all categories
                      _buildGeneralFields(),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Category specific fields
                      _buildCategorySpecificFields(),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons in a fixed bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          // Keep budget if set from home screen
                          final double? budget = _filterValues['maxPrice'];
                          _filterValues.clear();
                          if (budget != null) {
                            _filterValues['maxPrice'] = budget;
                            _filterValues['minPrice'] = 0.0;
                          }
                          _selectedState = null;
                          _selectedMaterialType = null;
                        });
                        // Add haptic feedback
                        HapticFeedback.selectionClick();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF000080),
                        side: const BorderSide(color: Color(0xFF000080)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39322),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Apply Filters'),
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

  // Format price for display
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  // Show dialog to edit budget
  void _showBudgetEditDialog() {
    final TextEditingController budgetController = TextEditingController(
      text: _filterValues['maxPrice'].toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Your Budget'),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixText: '₦ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final double budget = double.parse(budgetController.text.replaceAll(',', ''));
                setState(() {
                  _filterValues['maxPrice'] = budget;
                  _filterValues['minPrice'] = 0.0;
                });
              } catch (e) {
                // Handle parsing error
                print('Error parsing budget: $e');
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39322),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Build general fields that appear for all categories
  Widget _buildGeneralFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        // State dropdown
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(
            labelText: 'State',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _statesWithLGAs.map((state) {
            return DropdownMenuItem<String>(
              value: state.state,
              child: Text(state.state),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _updateFilter('state', value);
              // Clear selected LGAs when state changes
              _updateFilter('lgas', null);
            });
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 16),
        
        // LGA multi-select
        if (_selectedState != null) ...[
          const Text(
            'Local Government Areas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select LGAs in $_selectedState',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final stateWithLGAs = _statesWithLGAs.firstWhere(
                          (s) => s.state == _selectedState,
                        );
                        
                        final List<String> currentLGAs = List<String>.from(_filterValues['lgas'] ?? []);
                        
                        if (currentLGAs.length == stateWithLGAs.lgas.length) {
                          // If all are selected, clear selection
                          _updateFilter('lgas', []);
                        } else {
                          // Otherwise select all
                          _updateFilter('lgas', List<String>.from(stateWithLGAs.lgas));
                        }
                        
                        // Add haptic feedback
                        HapticFeedback.selectionClick();
                      },
                      child: Text(
                        _filterValues['lgas'] != null && 
                        _statesWithLGAs.firstWhere((s) => s.state == _selectedState).lgas.length == 
                        (_filterValues['lgas'] as List?)?.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF39322),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // LGA Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statesWithLGAs
                      .firstWhere((s) => s.state == _selectedState)
                      .lgas
                      .map((lga) {
                    final isSelected = (_filterValues['lgas'] as List?)?.contains(lga) ?? false;
                    
                    return FilterChip(
                      label: Text(
                        lga,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        final List<String> currentLGAs = List<String>.from(_filterValues['lgas'] ?? []);
                        
                        if (selected) {
                          currentLGAs.add(lga);
                        } else {
                          currentLGAs.remove(lga);
                        }
                        
                        _updateFilter('lgas', currentLGAs);
                        
                        // Add haptic feedback
                        HapticFeedback.selectionClick();
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF000080),
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        
        // Status field
        const Text(
          'Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        DropdownButtonFormField<String>(
          value: _filterValues['status'] as String?,
          decoration: InputDecoration(
            labelText: 'Property Status',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: const [
            DropdownMenuItem<String>(
              value: 'New',
              child: Text('New'),
            ),
            DropdownMenuItem<String>(
              value: 'Old',
              child: Text('Old'),
            ),
            DropdownMenuItem<String>(
              value: 'Renovated',
              child: Text('Renovated'),
            ),
            DropdownMenuItem<String>(
              value: 'Under Construction',
              child: Text('Under Construction'),
            ),
            DropdownMenuItem<String>(
              value: 'Off Market',
              child: Text('Off Market'),
            ),
            DropdownMenuItem<String>(
              value: 'Coming Soon',
              child: Text('Coming Soon'),
            ),
          ],
          onChanged: (value) {
            _updateFilter('status', value);
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
          isExpanded: true,
        ),
      ],
    );
  }

  // Build category specific fields
  Widget _buildCategorySpecificFields() {
    switch (widget.selectedCategory) {
      case 'residential':
        return _buildResidentialFields();
      case 'commercial':
        return _buildCommercialFields();
      case 'land':
        return _buildLandFields();
      case 'material':
        return _buildMaterialFields();
      default:
        return const SizedBox.shrink();
    }
  }

  // Build residential specific fields
  Widget _buildResidentialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 16),
        
        // Type dropdown
        DropdownButtonFormField<String>(
          value: _filterValues['type'] as String?,
          decoration: InputDecoration(
            labelText: 'Property Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _residentialTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            _updateFilter('type', value);
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
          isExpanded: true,
        ),
        const SizedBox(height: 16),
        
        // Function radio buttons
        const Text(
          'Function',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 16,
          children: ['Buy', 'Rent', 'Lease', 'Book'].map((function) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: function,
                  groupValue: _filterValues['function'] as String?,
                  onChanged: (value) {
                    _updateFilter('function', value);
                    // Add haptic feedback
                    HapticFeedback.selectionClick();
                  },
                  activeColor: const Color(0xFFF39322),
                ),
                Text(function),
              ],
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Price range slider
        const Text(
          'Price Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        RangeSlider(
          values: RangeValues(
            _filterValues['minPrice'] as double? ?? 0,
            _filterValues['maxPrice'] as double? ?? 100000000,
          ),
          min: 0,
          max: 100000000,
          divisions: 20,
          labels: RangeLabels(
            '₦${(_filterValues['minPrice'] as double? ?? 0).toStringAsFixed(0)}',
            '₦${(_filterValues['maxPrice'] as double? ?? 100000000).toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            _updateFilter('minPrice', values.start);
            _updateFilter('maxPrice', values.end);
          },
          activeColor: const Color(0xFFF39322),
          inactiveColor: Colors.grey[300],
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₦${_formatPrice(_filterValues['minPrice'] as double? ?? 0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₦${_formatPrice(_filterValues['maxPrice'] as double? ?? 100000000)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build commercial specific fields
  Widget _buildCommercialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 16),
        
        // Type dropdown
        DropdownButtonFormField<String>(
          value: _filterValues['type'] as String?,
          decoration: InputDecoration(
            labelText: 'Property Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _commercialTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            _updateFilter('type', value);
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
          isExpanded: true,
        ),
        const SizedBox(height: 16),
        
        // Function radio buttons
        const Text(
          'Function',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 16,
          children: ['Buy', 'Rent', 'Lease', 'Book'].map((function) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: function,
                  groupValue: _filterValues['function'] as String?,
                  onChanged: (value) {
                    _updateFilter('function', value);
                    // Add haptic feedback
                    HapticFeedback.selectionClick();
                  },
                  activeColor: const Color(0xFFF39322),
                ),
                Text(function),
              ],
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Price range slider
        const Text(
          'Price Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        RangeSlider(
          values: RangeValues(
            _filterValues['minPrice'] as double? ?? 0,
            _filterValues['maxPrice'] as double? ?? 100000000,
          ),
          min: 0,
          max: 100000000,
          divisions: 20,
          labels: RangeLabels(
            '₦${(_filterValues['minPrice'] as double? ?? 0).toStringAsFixed(0)}',
            '₦${(_filterValues['maxPrice'] as double? ?? 100000000).toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            _updateFilter('minPrice', values.start);
            _updateFilter('maxPrice', values.end);
          },
          activeColor: const Color(0xFFF39322),
          inactiveColor: Colors.grey[300],
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₦${_formatPrice(_filterValues['minPrice'] as double? ?? 0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₦${_formatPrice(_filterValues['maxPrice'] as double? ?? 100000000)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build land specific fields
  Widget _buildLandFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Land Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 16),
        
        // Type dropdown
        DropdownButtonFormField<String>(
          value: _filterValues['type'] as String?,
          decoration: InputDecoration(
            labelText: 'Land Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _landTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            _updateFilter('type', value);
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
          isExpanded: true,
        ),
        const SizedBox(height: 16),
        
        // Function radio buttons
        const Text(
          'Function',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 16,
          children: ['Buy', 'Lease', 'Book'].map((function) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: function,
                  groupValue: _filterValues['function'] as String?,
                  onChanged: (value) {
                    _updateFilter('function', value);
                    // Add haptic feedback
                    HapticFeedback.selectionClick();
                  },
                  activeColor: const Color(0xFFF39322),
                ),
                Text(function),
              ],
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Quantity dropdown
        DropdownButtonFormField<String>(
          value: _filterValues['quantity'] as String?,
          decoration: InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _landQuantities.map((quantity) {
            return DropdownMenuItem<String>(
              value: quantity,
              child: Text(quantity),
            );
          }).toList(),
          onChanged: (value) {
            _updateFilter('quantity', value);
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
          isExpanded: true,
        ),
        
        const SizedBox(height: 16),
        
        // Price range slider
        const Text(
          'Price Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        RangeSlider(
          values: RangeValues(
            _filterValues['minPrice'] as double? ?? 0,
            _filterValues['maxPrice'] as double? ?? 100000000,
          ),
          min: 0,
          max: 100000000,
          divisions: 20,
          labels: RangeLabels(
            '₦${(_filterValues['minPrice'] as double? ?? 0).toStringAsFixed(0)}',
            '₦${(_filterValues['maxPrice'] as double? ?? 100000000).toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            _updateFilter('minPrice', values.start);
            _updateFilter('maxPrice', values.end);
          },
          activeColor: const Color(0xFFF39322),
          inactiveColor: Colors.grey[300],
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₦${_formatPrice(_filterValues['minPrice'] as double? ?? 0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₦${_formatPrice(_filterValues['maxPrice'] as double? ?? 100000000)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build material specific fields
  Widget _buildMaterialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 16),
        
        // Type dropdown
        DropdownButtonFormField<String>(
          value: _selectedMaterialType,
          decoration: InputDecoration(
            labelText: 'Material Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _materialTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMaterialType = value;
              _updateFilter('type', value);
              // Clear quantity when type changes
              _updateFilter('quantity', null);
            });
            // Add haptic feedback
            HapticFeedback.selectionClick();
          },
          isExpanded: true,
        ),
        const SizedBox(height: 16),
        
        // Quantity dropdown (dynamic based on selected type)
        if (_selectedMaterialType != null) ...[
          DropdownButtonFormField<String>(
            value: _filterValues['quantity'] as String?,
            decoration: InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _getQuantityOptionsForMaterial(_selectedMaterialType!).map((quantity) {
              return DropdownMenuItem<String>(
                value: quantity,
                child: Text(quantity),
              );
            }).toList(),
            onChanged: (value) {
              _updateFilter('quantity', value);
              // Add haptic feedback
              HapticFeedback.selectionClick();
            },
            isExpanded: true,
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Price range slider
        const Text(
          'Price Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        
        RangeSlider(
          values: RangeValues(
            _filterValues['minPrice'] as double? ?? 0,
            _filterValues['maxPrice'] as double? ?? 1000000,
          ),
          min: 0,
          max: 1000000,
          divisions: 20,
          labels: RangeLabels(
            '₦${(_filterValues['minPrice'] as double? ?? 0).toStringAsFixed(0)}',
            '₦${(_filterValues['maxPrice'] as double? ?? 1000000).toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            _updateFilter('minPrice', values.start);
            _updateFilter('maxPrice', values.end);
          },
          activeColor: const Color(0xFFF39322),
          inactiveColor: Colors.grey[300],
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₦${_formatPrice(_filterValues['minPrice'] as double? ?? 0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₦${_formatPrice(_filterValues['maxPrice'] as double? ?? 1000000)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

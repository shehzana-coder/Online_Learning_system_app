import 'package:flutter/material.dart';

class PriceFilterScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tutors;
  final RangeValues selectedPriceRange;
  final Function(RangeValues) onApplyFilter;

  const PriceFilterScreen({
    Key? key,
    required this.tutors,
    required this.selectedPriceRange,
    required this.onApplyFilter,
  }) : super(key: key);

  @override
  _PriceFilterScreenState createState() => _PriceFilterScreenState();
}

class _PriceFilterScreenState extends State<PriceFilterScreen> {
  // Fixed price range from $0 to $500
  static const double _minPrice = 0.0;
  static const double _maxPrice = 500.0;

  late double _minPriceValue;
  late double _maxPriceValue;

  @override
  void initState() {
    super.initState();

    // Initialize selected values, clamping to valid bounds (0-500)
    _minPriceValue =
        widget.selectedPriceRange.start.clamp(_minPrice, _maxPrice);
    _maxPriceValue = widget.selectedPriceRange.end.clamp(_minPrice, _maxPrice);

    // Ensure max is greater than min
    if (_maxPriceValue <= _minPriceValue) {
      _maxPriceValue = (_minPriceValue + 10.0).clamp(_minPrice, _maxPrice);
    }

    print(
        'Price range: \$${_minPrice.toInt()} - \$${_maxPrice.toInt()}'); // Debug
    print(
        'Selected min: \$${_minPriceValue.toInt()}, max: \$${_maxPriceValue.toInt()}'); // Debug
  }

  void _updateMinPrice(double value) {
    setState(() {
      _minPriceValue = value.clamp(_minPrice, _maxPrice);
      // Ensure min is at least $10 less than max
      if (_minPriceValue >= _maxPriceValue - 10) {
        _maxPriceValue = (_minPriceValue + 10.0).clamp(_minPrice, _maxPrice);
      }
      print('Updated min price: \$${_minPriceValue.toInt()}'); // Debug
    });
  }

  void _updateMaxPrice(double value) {
    setState(() {
      _maxPriceValue = value.clamp(_minPrice, _maxPrice);
      // Ensure max is at least $10 more than min
      if (_maxPriceValue <= _minPriceValue + 10) {
        _minPriceValue = (_maxPriceValue - 10.0).clamp(_minPrice, _maxPrice);
      }
      print('Updated max price: \$${_maxPriceValue.toInt()}'); // Debug
    });
  }

  void _clearFilters() {
    setState(() {
      _minPriceValue = _minPrice;
      _maxPriceValue = _maxPrice;
      print(
          'Cleared prices: \$${_minPriceValue.toInt()} - \$${_maxPriceValue.toInt()}'); // Debug
    });
  }

  void _applyFilters() {
    print(
        'Applying price range: \$${_minPriceValue.toInt()} - \$${_maxPriceValue.toInt()}'); // Debug
    widget.onApplyFilter(RangeValues(_minPriceValue, _maxPriceValue));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Price Filter',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Price range info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Price Range',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose between \$0 - \$500',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Clear all button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color.fromARGB(255, 255, 144, 187),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Selected range display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${_minPriceValue.toInt()} - \$${_maxPriceValue.toInt()} selected',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Minimum price selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Minimum Price',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${_minPriceValue.toInt()}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Color.fromARGB(255, 255, 144, 187),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _minPriceValue,
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 50, // Creates 50 divisions for $10 increments
                    activeColor: const Color.fromARGB(255, 255, 144, 187),
                    inactiveColor: Colors.grey[300],
                    onChanged: _updateMinPrice,
                  ),
                ],
              ),
            ),

            // Maximum price selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Maximum Price',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${_maxPriceValue.toInt()}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Color.fromARGB(255, 255, 144, 187),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _maxPriceValue,
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 50, // Creates 50 divisions for $10 increments
                    activeColor: const Color.fromARGB(255, 255, 144, 187),
                    inactiveColor: Colors.grey[300],
                    onChanged: _updateMaxPrice,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Apply Price Filter',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

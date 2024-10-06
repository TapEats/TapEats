import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> menuItems = [];
  List<String> categories = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  /// Fetch menu items and manually extract distinct categories
  Future<void> _fetchMenuData() async {
    final response = await supabase
        .from('menu')
        .select('*');  // Fetch all menu items

    if (response.isNotEmpty) {
      Set<String> uniqueCategories = {};
      setState(() {
        menuItems = response;
        for (var item in response) {
          uniqueCategories.add(item['category'].toString());
        }
        categories = uniqueCategories.toList();
        if (categories.isNotEmpty) {
          selectedCategory = categories[0];  // Set the first category as default
        }
      });
    } else {
      if (kDebugMode) {
        print('Error fetching menu data');
      }
    }
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Widget with fixed location icon
            HeaderWidget(
              leftIcon: Iconsax.user,
              onLeftButtonPressed: () {},
              headingText: 'Vadodara',
              headingIcon: Iconsax.location,
              rightIcon: Iconsax.menu,
              onRightButtonPressed: () {},
            ),
            const SizedBox(height: 40),
            // "Fuel Your Flavor Adventure" Text with Image of Macarons
            _buildFlavorAdventureSection(),
            const SizedBox(height: 20),
            // Search bar widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomSearchBar(
                controller: TextEditingController(),
                hintText: 'Find your cravings',
                onSearch: () {
                  if (kDebugMode) {
                    print('Search triggered');
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            // Categories (fetched from the menu table)
            _buildCategoryButtons(),
            const SizedBox(height: 20),
            // Food Menu Scrollable Items
            _buildMenuItems(),
            const SizedBox(height: 20),
            // Slider Button widget for cart or other action
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: SliderButton(  
                labelText: 'Cart',  // Change the label as per your needs
                subText: '1 item',  // Change the subtext as per your needs
              ),
            ),

const SizedBox(height: 40),
            // Footer widget at the bottom
            const CustomFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlavorAdventureSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Fuel Your Flavor Adventure',
              style: GoogleFonts.greatVibes(
                color: const Color(0xFFEEEFEF),
                fontSize: 48,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 1,
            child: Image.asset(
              'assets/images/macaroon_1.png',  // Path to the macaroon image
              fit: BoxFit.contain,
              height: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: categories.map((category) {
          bool isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () => _selectCategory(category),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF222222) : const Color(0xFF1A1A1A),  // Adjusted background color
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),  // Slightly reduced height
                child: Text(
                  category,  // Display category name
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),  // Adjusted text color
                    fontFamily: 'Helvetica Neue',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItems() {
    final filteredMenuItems = menuItems.where((item) => item['category'] == selectedCategory).toList();
    
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: filteredMenuItems.map((item) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item['image_url'],
                        fit: BoxFit.cover,
                        height: 120,
                        width: 180,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        item['name'],
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '\$${item['price'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFFD0F0C0)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.yellow, size: 14),
                          Text(
                            item['ratings'].toString(),
                            style: const TextStyle(color: Color(0xFFEEEFEF)),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.timer, color: Color(0xFFEEEFEF), size: 14),
                          Text(
                            '${item['time']}min',
                            style: const TextStyle(color: Color(0xFFEEEFEF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

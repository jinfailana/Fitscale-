import 'package:flutter/material.dart';
import 'set_height.dart';

class BirthYearPage extends StatefulWidget {
  const BirthYearPage({super.key});

  @override
  State<BirthYearPage> createState() => _BirthYearPageState();
}

class _BirthYearPageState extends State<BirthYearPage> {
  int? selectedYear;
  final List<int> years = List.generate(100, (index) => DateTime.now().year - index);

  @override   
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(51, 50, 50, 1.0),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(223, 77, 15, 1.0)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birth Year',
                style: TextStyle(
                  color: Color.fromRGBO(223, 77, 15, 1.0),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Helps us tailor recommendations based on your age and stage of life',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    return _yearButton(years[index]);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 350,
                child: ElevatedButton(
                  onPressed: selectedYear != null ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetHeightPage()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yearButton(int year) {
    bool isSelected = selectedYear == year;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedYear = year;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            year.toString(),
            style: TextStyle(
              color: isSelected ? const Color.fromRGBO(223, 77, 15, 1.0) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

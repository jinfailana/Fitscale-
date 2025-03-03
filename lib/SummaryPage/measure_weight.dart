import 'package:flutter/material.dart';

class MeasureWeightPage extends StatefulWidget {
  const MeasureWeightPage({Key? key}) : super(key: key);

  @override
  _MeasureWeightPageState createState() => _MeasureWeightPageState();
}

class _MeasureWeightPageState extends State<MeasureWeightPage> {
  double weight = 0.0;  // Initialize weight to 0

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Summary',
          style: TextStyle(color: Color.fromRGBO(223, 77, 15, 1.0), // Changed to orange
          fontSize: 18,
        ),
        ),
        backgroundColor: const Color.fromRGBO(45, 45, 45, 1.0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(223, 77, 15, 1.0)),  // Orange back button
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color.fromRGBO(45, 45, 45, 1.0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14.0), // Adjust this value as needed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weight',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'See your changes',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(  // Center the weight container
              child: Container(
                width: 300,
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(28, 28, 30, 1.0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color.fromRGBO(223, 77, 15, 1.0), width: 2),  // Orange border
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,  // Center the contents
                  children: [
                    Text(
                      '${weight.toStringAsFixed(1)} kg',  // Display weight
                      style: const TextStyle(
                        fontSize: 50 * 0.9,  // 10% smaller
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(223, 77, 15, 1.0),  // Orange color
                      ),
                    ),
                    const SizedBox(width: 10),  // Space between weight and icon
                    const Icon(
                      Icons.monitor_weight,  // Icon on the right side
                      color: Color.fromRGBO(223, 77, 15, 1.0),
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic to connect to smart scale can be added here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(223, 77, 15, 1.0),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),  // Adjusted border radius
                ),
              ),
              child: const Text(
                'Connect to Smart Scale',
                style: TextStyle(color: Colors.white),  // Changed font color to white
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Logic to save weight can be added here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(45, 45, 45, 1.0),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),  // Adjusted border radius
                ),
              ),
              child: const Text(
                'Save Weight',
                style: TextStyle(color: Colors.white),  // Changed font color to white
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Weight History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                
              ),
            ),
            const SizedBox(height: 10),
            // Weight History Table
            Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(28, 28, 30, 1.0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color.fromRGBO(223, 77, 15, 1.0), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Color.fromRGBO(223, 77, 15, 1.0), width: 1),
                    verticalInside: BorderSide(color: Color.fromRGBO(223, 77, 15, 1.0), width: 1),
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: const Color.fromRGBO(223, 77, 15, 0.1)),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center( // Center align text
                            child: Text(
                              'Weight',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center( // Center align text
                            child: Text(
                              'Date',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Placeholder for weight history data
                    TableRow(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No weight history available.', style: TextStyle(color: Colors.grey)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
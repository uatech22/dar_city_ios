import 'package:flutter/material.dart';



class NewsListScreen extends StatelessWidget {
  final List<Map<String, String>> newsArticles = [
    {
      'title': "Dar City's Newest Star Player",
      'timeAgo': '2d ago',
      'image': 'assets/images/dar-city-logo.png' // Replace with actual image URL
    },
    {
      'title': "Dar City's Game Schedule",
      'timeAgo': '3d ago',
       'image': 'assets/images/ground.jpg' // Replace with actual image URL
    },





  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
        TextField(
        decoration: InputDecoration(
            hintText: 'Search news',
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey,
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    ),
    ),
    const SizedBox(height: 20),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: const [
    FilterButton(label: 'Recent'),
    FilterButton(label: 'Popular'),
    FilterButton(label: 'Categories'),
    ],
    ),
    const SizedBox(height: 20),
    Expanded(
    child: ListView.builder(
    itemCount: newsArticles.length,
    itemBuilder: (context, index) {
    final article = newsArticles[index];
    return _buildNewsCard(article['title']!, article['timeAgo']!, article['image']! );
    },
    ),
    ),
    ],
    ),
    ),
    );
  }

  Widget _buildNewsCard(String title, String timeAgo, String imageUrl) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
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
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;

  const FilterButton({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
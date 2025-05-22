import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40), 
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2cac69)),
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'About',
                    style: TextStyle(
                      color: Color(0xFF2cac69), 
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: Image.asset(
                  'assets/images/logo1.png', 
                  height: 100,
                  width: 100,
                ),
              ),
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'WasteApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2cac69),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Version App v1.5.5',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'About WasteApp',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2cac69),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'WasteApp is a sustainable waste management solution designed to help users properly dispose of waste and contribute to a cleaner environment. '
                'Our app provides education on waste segregation, recycling tips, and connects users to waste collection services.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Our Team',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2cac69),
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _teamMemberCard('Andi Muh Naufal Dzaky', 'Team Lead',
                      'assets/images/team_member1.jpg'),
                  _teamMemberCard('Ahmad syafii', 'UX Designer',
                      'assets/images/team_member2.jpg'),
                  _teamMemberCard('Adryan Efan Cesyllas', 'Developer',
                      'assets/images/team_member3.jpg'),
                  _teamMemberCard('M.Rayhan Efendi', 'Content Manager',
                      'assets/images/team_member4.jpg'),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2cac69),
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.email, color: Color(0xFF2cac69)),
                title:  Text('Email'),
                subtitle:  Text('support@wasteapp.com'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamMemberCard(String name, String role, String imagePath) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(imagePath),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
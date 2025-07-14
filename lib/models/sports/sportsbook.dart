class Sportsbook { // Define Sportsbook class as a data model for sports betting platforms
  final String id; // Declare final string field for unique sportsbook identifier
  final String name; // Declare final string field for the name of the sportsbook
  final bool isEnabled; // Declare final boolean field for whether the sportsbook is currently enabled
  final String? logoUrl; // Declare optional final string field for the sportsbook's logo URL

  Sportsbook({ // Constructor for Sportsbook class with required and optional parameters
    required this.id, // Initialize required id parameter
    required this.name, // Initialize required name parameter
    required this.isEnabled, // Initialize required isEnabled parameter
    this.logoUrl, // Initialize optional logoUrl parameter
  }); // End of constructor

  factory Sportsbook.fromJson(Map<String, dynamic> json) { // Define factory constructor to create Sportsbook from JSON
    return Sportsbook( // Return a new Sportsbook instance
      id: json['id'], // Extract id from 'id' key in JSON
      name: json['name'], // Extract name from 'name' key in JSON
      isEnabled: json['is_enabled'] ?? true, // Extract isEnabled from 'is_enabled' key with default value of true
      logoUrl: json['logo_url'], // Extract logoUrl from 'logo_url' key in JSON
    ); // End of Sportsbook constructor call
  } // End of fromJson factory constructor

  Map<String, dynamic> toJson() { // Define method to convert Sportsbook instance to JSON
    return { // Return a Map with sportsbook properties
      'id': id, // Map id field to 'id' key
      'name': name, // Map name field to 'name' key
      'is_enabled': isEnabled, // Map isEnabled field to 'is_enabled' key
      'logo_url': logoUrl, // Map logoUrl field to 'logo_url' key
    }; // End of Map literal
  } // End of toJson method
} // End of Sportsbook class

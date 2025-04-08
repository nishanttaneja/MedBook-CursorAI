# MedBook - AI-Assisted Medical Book Search App

![MedBook Logo](Assets.xcassets/AppIcon.appiconset/Icon-1024.png)

## Overview

MedBook is a modern iOS application that allows users to search for medical books, view details, and manage bookmarks. The app provides a seamless experience for medical professionals and students to find relevant literature. Built with UIKit and following the MVVM architecture, MedBook demonstrates the power of AI-assisted development in creating production-ready applications.

## Features

- **Book Search**: Search for medical books with real-time results from the Open Library API
- **Bookmarking**: Save your favorite books for quick access with Core Data persistence
- **Sorting Options**: Sort books by title, rating, or popularity
- **User Authentication**: Secure login and registration with email/password
- **Offline Access**: Access your bookmarked books without internet connection
- **Responsive UI**: Beautiful and intuitive interface with dark mode support
- **Error Handling**: Robust error handling with user-friendly messages and automatic retries

## AI-Assisted Development

This project was developed with the assistance of Cursor AI, an advanced AI coding assistant. The development process demonstrated significant advantages over traditional development:

### Time Efficiency

- **Traditional Development**: Estimated 40-50 hours
- **AI-Assisted Development**: Completed in approximately 15-20 hours
- **Time Savings**: ~60% reduction in development time

### Bug Resolution

- **Bug Detection**: AI assistant identified potential issues before they became problems
- **Bug Fixes**: Resolved approximately 15 bugs during development
- **Iteration Speed**: Quick iterations allowed for rapid refinement of features

### Development Process

The AI assistant helped with:

1. **Architecture Design**: Suggested MVVM architecture with clear separation of concerns
2. **Code Generation**: Wrote boilerplate code and complex implementations
3. **Error Handling**: Implemented robust error handling and retry mechanisms
4. **UI Components**: Created responsive and accessible UI components
5. **Data Management**: Designed efficient data models and persistence strategies
6. **API Integration**: Implemented clean API integration with proper error handling
7. **Testing**: Suggested test cases and edge scenarios to consider

### Key Challenges Overcome

1. **Search Retry Logic**: Implemented robust retry mechanism for handling server errors
2. **Bookmark Synchronization**: Ensured proper synchronization between local and remote data
3. **UI State Management**: Managed complex UI states during loading and error conditions
4. **Core Data Integration**: Properly integrated Core Data for offline storage
5. **Error Handling**: Created user-friendly error messages for various failure scenarios

### Development Experience with AI

Working with Cursor AI provided several unique advantages:

- **Rapid Prototyping**: Quickly implemented and tested different approaches to features
- **Code Consistency**: Maintained consistent coding style and patterns throughout the project
- **Problem Solving**: AI suggested multiple solutions to complex problems
- **Documentation**: Generated inline documentation and comments for better code understanding
- **Learning Opportunity**: Explained complex concepts and best practices during development

## Technical Stack

- **Language**: Swift 5.9
- **Architecture**: MVVM (Model-View-ViewModel)
- **UI Framework**: UIKit
- **Data Persistence**: Core Data
- **Networking**: URLSession with async/await
- **Dependency Management**: Manual (no external dependencies)
- **API**: Open Library Search API

## Project Structure

```
MedBook/
├── Models/           # Data models and Core Data entities
├── Views/            # Custom UI components
├── ViewControllers/  # Screen controllers
├── ViewModels/       # View models for MVVM architecture
├── Services/         # Business logic and API services
├── Core/             # Core functionality and utilities
└── Resources/        # Assets and configuration files
```

## Getting Started

1. Clone the repository
2. Open `MedBook.xcodeproj` in Xcode 15+
3. Build and run the project

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Open Library API](https://openlibrary.org/dev/docs/api/search) for book data
- Cursor AI for AI-assisted development
- The Swift and iOS developer community for inspiration and resources 
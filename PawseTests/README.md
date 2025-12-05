# Pawse Test Suite

Comprehensive test coverage for the Pawse iOS application.

## Test Structure

```
PawseTests/
├── ControllerTests/        # Backend API integration tests
├── ModelTests/             # Data model validation tests
├── ViewModelTests/         # ViewModel logic and state management tests
├── Helpers/               # Test utilities and mocks
```

## Test Coverage

### Controllers
Basic functions of all controllers being tested, but didn't reach 90% coverage due to complicated logic and calling real database. Tried to use mock tests, but those didn't touch the real database and thus also produce poor coverage.

### Models
Full coverage for all models

### ViewModels
- **PetViewModelTests**: Pet management
- **ConnectionViewModelTests**: Friend connections
- **ContestViewModelTests**: Contest operations

## Running Tests
You have to login as a user, and then run the tests in Xcode.

## Key Points
- Focus on state management, business logic, and error handling.
- Controller tests include real Firebase/AWS calls.

## Limitations
- Authentication tests such as the auth controller and the user view models are limited to avoid global state issues.

## Future Improvements
- Add protocol-based mocks for better isolation.
- Expand integration tests for full backend coverage.

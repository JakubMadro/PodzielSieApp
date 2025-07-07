// Request DTO - User
const CreateUserDto = require('./request/user/CreateUserDto');
const UpdateUserDto = require('./request/user/UpdateUserDto');
const LoginUserDto = require('./request/user/LoginUserDto');
const ChangePasswordDto = require('./request/user/ChangePasswordDto');
const RefreshTokenDto = require('./request/user/RefreshTokenDto');
const SearchQueryDto = require('./request/user/SearchQueryDto');

// Response DTO - User
const UserDto = require('./response/user/UserDto');
const UserProfileDto = require('./response/user/UserProfileDto');

// Mappers
const UserMapper = require('./mappers/UserMapper');
const ActivityMapper = require('./mappers/ActivityMapper');

module.exports = {
    // Request DTO - User
    CreateUserDto,
    UpdateUserDto,
    LoginUserDto,
    ChangePasswordDto,
    RefreshTokenDto,
    SearchQueryDto,

    // Response DTO - User
    UserDto,
    UserProfileDto,

    // Mappers
    UserMapper,
    ActivityMapper
};
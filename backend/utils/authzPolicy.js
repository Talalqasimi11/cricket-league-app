// utils/authzPolicy.js
// Central authorization policy mapping roles to scopes and required scopes per route group

const ROLE_SCOPE_MAPPING = {
  captain: [
    'team:read',
    'team:manage', 
    'match:score',
    'player:manage',
    'player:read',
    'tournament:manage',
    'tournament:read'
  ],
  admin: [
    'team:read',
    'team:manage',
    'match:score', 
    'player:manage',
    'player:read',
    'tournament:manage',
    'tournament:read',
    'admin:all'
  ]
};

const ROUTE_SCOPE_REQUIREMENTS = {
  // Team management
  'GET /api/teams': [], // Public
  'GET /api/teams/my-team': ['team:read'],
  'PUT /api/teams/update': ['team:manage'],
  'DELETE /api/teams/my-team': ['team:manage'],
  'GET /api/teams/:id': [], // Public
  
  // Player management
  'POST /api/players': ['player:manage'],
  'GET /api/players/my-players': ['player:read'],
  'PUT /api/players/:id': ['player:manage'],
  'DELETE /api/players/:id': ['player:manage'],
  'GET /api/players/team/:team_id': [], // Public
  
  // Match scoring
  'POST /api/live-score/start-innings': ['match:score'],
  'POST /api/live-score/ball': ['match:score'],
  'POST /api/live-score/end-innings': ['match:score'],
  'GET /api/live-score/:match_id': [], // Public
  'POST /api/live-score/deliveries': ['match:score'],
  
  // Tournament management
  'POST /api/tournaments': ['tournament:manage'],
  'GET /api/tournaments': [], // Public
  'PUT /api/tournaments/:id': ['tournament:manage'],
  'DELETE /api/tournaments/:id': ['tournament:manage'],
  'POST /api/tournaments/create': ['tournament:manage'],
  'PUT /api/tournaments/update': ['tournament:manage'],
  'DELETE /api/tournaments/delete': ['tournament:manage'],
  
  // Admin routes
  'GET /api/admin/dashboard': ['admin:all'],
  'GET /api/admin/users': ['admin:all'],
  'PUT /api/admin/users/:userId/admin': ['admin:all'],
  'DELETE /api/admin/users/:userId': ['admin:all'],
  'GET /api/admin/teams': ['admin:all'],
  'GET /api/admin/teams/:teamId': ['admin:all'],
  'PUT /api/admin/teams/:teamId': ['admin:all'],
  'DELETE /api/admin/teams/:teamId': ['admin:all'],
  
  // Auth routes (no scopes required)
  'POST /api/auth/register': [],
  'POST /api/auth/login': [],
  'POST /api/auth/refresh': [],
  'POST /api/auth/logout': [],
  'POST /api/auth/forgot-password': [],
  'POST /api/auth/verify-reset': [],
  'POST /api/auth/reset-password': [],
  'PUT /api/auth/change-password': [],
  'PUT /api/auth/change-phone': []
};

/**
 * Get scopes for a given role
 * @param {string} role - User role
 * @returns {string[]} Array of scopes
 */
function getScopesForRole(role) {
  return ROLE_SCOPE_MAPPING[role] || [];
}

/**
 * Get required scopes for a route
 * @param {string} method - HTTP method
 * @param {string} path - Route path
 * @returns {string[]} Array of required scopes
 */
function getRequiredScopesForRoute(method, path) {
  const routeKey = `${method.toUpperCase()} ${path}`;
  return ROUTE_SCOPE_REQUIREMENTS[routeKey] || [];
}

/**
 * Check if user has required scopes for a route
 * @param {string[]} userScopes - User's scopes
 * @param {string} method - HTTP method
 * @param {string} path - Route path
 * @returns {boolean} True if user has required scopes
 */
function hasRequiredScopes(userScopes, method, path) {
  const requiredScopes = getRequiredScopesForRoute(method, path);
  return requiredScopes.every(scope => userScopes.includes(scope));
}

module.exports = {
  ROLE_SCOPE_MAPPING,
  ROUTE_SCOPE_REQUIREMENTS,
  getScopesForRole,
  getRequiredScopesForRoute,
  hasRequiredScopes
};

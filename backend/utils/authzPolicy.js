// utils/authzPolicy.js
// Central authorization policy mapping roles to scopes and required scopes per route group

const ROLE_SCOPE_MAPPING = {
  captain: [
    'team:read',
    'team:manage', 
    'match:score',
    'player:manage',
    'tournament:manage'
  ],
  admin: [
    'team:read',
    'team:manage',
    'match:score', 
    'player:manage',
    'tournament:manage',
    'admin:all'
  ]
};

const ROUTE_SCOPE_REQUIREMENTS = {
  // Team management
  'POST /api/teams': ['team:manage'],
  'PUT /api/teams/:id': ['team:manage'],
  'DELETE /api/teams/:id': ['team:manage'],
  'GET /api/teams/my-team': ['team:read'],
  
  // Player management
  'POST /api/players': ['player:manage'],
  'PUT /api/players/:id': ['player:manage'],
  'DELETE /api/players/:id': ['player:manage'],
  'GET /api/players/my-players': ['player:read'],
  
  // Match scoring
  'POST /api/live-score/start-innings': ['match:score'],
  'POST /api/live-score/ball': ['match:score'],
  'POST /api/live-score/end-innings': ['match:score'],
  'POST /api/deliveries': ['match:score'],
  
  // Tournament management
  'POST /api/tournaments': ['tournament:manage'],
  'PUT /api/tournaments/:id': ['tournament:manage'],
  'DELETE /api/tournaments/:id': ['tournament:manage'],
  'POST /api/tournaments/create': ['tournament:manage'],
  'PUT /api/tournaments/update': ['tournament:manage'],
  'DELETE /api/tournaments/delete': ['tournament:manage']
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

const jwt = require('jsonwebtoken');

const authorizeRoles = (allowedRoles) => {
    return (req, res, next) => {
        const token = req.header("Authorization")?.split(" ")[1];
        if (!token) {
            return res.status(401).json({ error: "Token not provided" });
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.user = decoded;

            if (!allowedRoles.includes(req.user.role)) {
                return res.status(403).json({ error: "Access denied, role not authorized" });
            }

            next();
        } catch (err) {
            return res.status(401).json({ error: "Invalid or expired token" });
        }
    };
};

module.exports = authorizeRoles;
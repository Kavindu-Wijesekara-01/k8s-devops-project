# Base image එක විදිහට Node.js භාවිතා කිරීම
FROM node:18-alpine

# Working directory එක සෑදීම
WORKDIR /usr/src/app

# package.json ෆයිල් එක කොපි කිරීම
COPY package*.json ./

# Dependencies install කිරීම
RUN npm install

# Application code එක කොපි කිරීම
COPY . .

# Port 3000 Expose කිරීම
EXPOSE 3000

# Application එක Run කිරීම
CMD [ "npm", "start" ]
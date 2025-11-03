# Fred139 Project

A modern web application built with Node.js and Express, deployed on Google Cloud Platform.

## 🚀 Features

- RESTful API with Express.js
- Docker containerization
- GitHub Actions CI/CD pipeline
- Google Cloud Platform deployment
- Health monitoring endpoints

## 🛠️ Technology Stack

- **Runtime**: Node.js 18
- **Framework**: Express.js
- **Cloud Platform**: Google Cloud Platform
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Version Control**: GitHub

## 🏃‍♂️ Quick Start

### Prerequisites

- Node.js 18 or higher
- npm or yarn
- Docker (for containerization)
- Google Cloud CLI (for deployment)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/fred-lgtm/fred139-project.git
cd fred139-project
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Open your browser and navigate to `http://localhost:3000`

## 🐳 Docker

Build and run the container:

```bash
# Build the image
docker build -t fred139-project .

# Run the container
docker run -p 3000:3000 fred139-project
```

## ☁️ Deployment

This project is configured for deployment on Google Cloud Platform using Cloud Run.

### Automatic Deployment

The project includes GitHub Actions workflows that automatically deploy to GCP when you push to the main branch.

### Manual Deployment

```bash
# Deploy to Cloud Run
gcloud run deploy fred139-project \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## 📊 API Endpoints

- `GET /` - Welcome message and project info
- `GET /health` - Health check endpoint

## 🧪 Testing

```bash
npm test
```

## 🔧 Development

```bash
# Run in development mode with auto-reload
npm run dev

# Lint code
npm run lint

# Build project
npm run build
```

## 📝 License

MIT License - see LICENSE file for details

## 👨‍💻 Author

Frederick (fred@brickface.com)

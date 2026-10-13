# Task 4 exactly as the task describes it (needs Docker Hub). NOT run in my lab environment.
# Put it next to ../web-app/index.html, then:
#   docker build -t my-website:v1 -f web-app.Dockerfile ../web-app
#   docker run -d -p 8080:80 my-website:v1     # open http://localhost:8080
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html

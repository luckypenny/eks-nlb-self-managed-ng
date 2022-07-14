FROM python:3.6-alpine
RUN pip install flask==1.0.2
EXPOSE 8080
COPY . /app
ENTRYPOINT ["python"]
CMD ["app.py"]
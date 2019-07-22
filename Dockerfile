FROM puckel/docker-airflow:1.10.3

COPY entrypoint.sh /entrypoint.sh

USER root

RUN pip install apache-airflow['kubernetes']

USER airflow

ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint

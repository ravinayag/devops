FROM continuumio/miniconda3
RUN conda create -n freelancer python=3.6.6 -y
RUN echo "source activate freelancer" > ~/.bashrc
ENV PATH /opt/conda/envs/freelancer/bin:$PATH

RUN mkdir /app
COPY ./requirements.txt /app/
WORKDIR /app

RUN pip --version
RUN . /opt/conda/etc/profile.d/conda.sh && \
 conda activate freelancer && \
 conda install -c dansondergaard tmhmm.py  -y && \
 conda install -c bioconda hmmer -y && \
 pip install numpy && \
 pip install django && \
 pip install django-chartjs && \
 pip install biopython && \
 pip install bs4 && \
 pip install plotly==3.10.0 && \
 pip install gunicorn==19.9.0
#RUN while read requirement; do conda install -c $requirement -y || pip install $requirement; done < conda.txt
EXPOSE 8000
#CMD exec gunicorn app.wsgi:application --bind 0.0.0.0:8000 --workers 3

RUN apt-get update
RUN apt install hmmer -y
RUN apt install 
RUN pip install -r requirements.txt

COPY ./app /app
COPY ./start.sh /app/start.sh




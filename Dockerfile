FROM continuumio/miniconda3
RUN conda create -n freelencer python=3.6.6 -y
RUN echo "source activate freelencer" > ~/.bashrc
ENV PATH /opt/conda/envs/freelencer/bin:$PATH

RUN mkdir /codedj
COPY ./requirements.txt /codedj/
WORKDIR /codedj

RUN pip --version
RUN . /opt/conda/etc/profile.d/conda.sh && \
 conda activate freelencer && \
 conda install -c dansondergaard tmhmm.py  -y && \
 conda install -c bioconda hmmer -y && \
 pip install numpy==1.13.3 && \
 pip install django && \
 pip install django-chartjs && \
 pip install biopython && \
 pip install selenium && \
 pip install bs4 && \
 pip install pdfkit && \
 pip install  plotly==3.10.0
 pip install gunicorn==19.9.0
EXPOSE 8000
CMD exec gunicorn your_site_name.wsgi:application --bind 0.0.0.0:8000 --workers 3
#RUN while read requirement; do conda install -c $requirement -y || pip install $requirement; done < conda.txt

RUN apt-get update
RUN apt install hmmer -y
RUN apt install 
RUN pip install -r requirements.txt

RUN mkdir /app
WORKDIR /app
COPY ./app /app

RUN . /opt/conda/etc/profile.d/conda.sh && \
 conda activate freelencer && \
 conda install -c dansondergaard tmhmm.py  -y && \
 conda install -c bioconda hmmer -y && \
 pip install numpy && \
 pip install django && \
 pip install django-chartjs && \
 pip install biopython && \
 pip install selenium && \
 pip install bs4 && \
 pip install pdfkit && \
 pip install  plotly==3.10.0


#RUN pip install -r requirements.txt
COPY ./start.sh /app/start.sh


docker run -i -t docker_django /bin/bash


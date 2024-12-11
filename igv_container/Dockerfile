FROM node:latest

RUN apt-get update && apt-get install -y \
	wget

RUN mkdir -p /opt/apps/igv
WORKDIR /opt/apps/igv

RUN wget https://igv.org/app-archive/igv-webapp.3.0.7.zip
RUN unzip igv-webapp.3.0.7.zip
RUN rm igv-webapp.3.0.7.zip

WORKDIR /
COPY init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 8080
CMD [ "/init.sh" ]
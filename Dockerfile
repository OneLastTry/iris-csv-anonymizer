ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community:2022.2.0.281.0
FROM $IMAGE

LABEL maintainer="Renan Lourenco <renan.lourenco@intersystems.com>"

ENV IRIS_USERNAME="SuperUser"
ENV IRIS_PASSWORD="SYS"
ENV IRIS_PROJECT="/src/"

USER ${ISC_PACKAGE_MGRUSER}
COPY ./Installer.cls /tmp/Installer.cls
COPY ./src/Anonymizer /tmp/src/Anonymizer
COPY ./scripts/irissession.sh /tmp/irissession.sh
USER root
RUN chmod 775 /tmp/irissession.sh
RUN chmod +x /tmp/irissession.sh
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /tmp/irissession.sh
RUN sed -i -e 's/\r$//' /tmp/irissession.sh
USER ${ISC_PACKAGE_MGRUSER}
RUN echo "$IRIS_PASSWORD" >> /tmp/pwd.isc && /usr/irissys/dev/Container/changePassword.sh /tmp/pwd.isc

SHELL ["/tmp/irissession.sh"]
RUN \
  do $SYSTEM.OBJ.Load("/tmp/Installer.cls", "ck") \
  set sc = ##class(Anonymizer.Installer).Install("/tmp/src/Anonymizer")
  
SHELL ["/bin/bash", "-c"]
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]

HEALTHCHECK --interval=5s CMD /irisHealth.sh || exit 1

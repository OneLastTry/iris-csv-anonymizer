ARG ARCH
ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community$ARCH:2022.2.0.304.0
FROM $IMAGE AS Builder

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

# 2nd stage to reduce size
FROM $IMAGE AS Main
LABEL maintainer "Renan Lourenço <renan.lourenco@intersystems.com>"
USER root
# replace in standard kit with what we modified in first stage
COPY --from=Builder /usr/irissys/iris.cpf /usr/irissys/.
COPY --from=Builder /usr/irissys/mgr/IRIS.DAT /usr/irissys/mgr/.
COPY --from=Builder /usr/irissys/mgr/hssys/IRIS.DAT /usr/irissys/mgr/hssys/.
COPY --from=Builder /usr/irissys/mgr/appl/. /usr/irissys/mgr/appl/.
# need to reset ownership for files copied
RUN \
  chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/iris.cpf \
  && chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/mgr/IRIS.DAT \
  && chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/mgr/appl \
  && chmod -R 775 /usr/irissys/mgr/appl/IRIS.DAT

USER ${ISC_PACKAGE_MGRUSER}

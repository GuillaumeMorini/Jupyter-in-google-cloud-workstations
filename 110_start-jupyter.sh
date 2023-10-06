# Configure container startup
export PATH=/opt/conda/bin:$PATH
su user -l -c "export PATH=/opt/coda/bin:$PATH && jupyter lab  --IdentityProvider.token='' --ServerApp.allow_origin='*' --port $JUPYTER_PORT"

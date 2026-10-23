FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY publish/ ./
COPY data/ ./data/
RUN mkdir -p /app/Exceptions /app/Diagnostics && chown $APP_UID:$APP_UID /app/Exceptions /app/Diagnostics
USER $APP_UID
ENTRYPOINT ["dotnet", "GenOnlineService.dll"]

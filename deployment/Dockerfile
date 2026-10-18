FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY publish/ ./
COPY data/ ./data/
RUN mkdir -p /app/Exceptions && chown $APP_UID:$APP_UID /app/Exceptions
USER $APP_UID
ENTRYPOINT ["dotnet", "GenOnlineService.dll"]

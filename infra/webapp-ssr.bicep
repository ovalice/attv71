param name string
param location string = resourceGroup().location

param appRegistrationClientId string
@secure()
param appRegistrationClientSecret string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  location: location
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      ftpsState: 'Disabled'
      linuxFxVersion: 'Node|18'
      http20Enabled: true
      appSettings: [
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '3~'
        }
        {
          name: 'WEBAPP_SSR_ENTRA_CLIENT_SECRET'
          value: appRegistrationClientSecret
        }
      ]
    }
  }

  resource authentication 'config' = {
    name: 'authsettingsV2'
    properties: {
      globalValidation: {
        requireAuthentication: true
        unauthenticatedClientAction: 'RedirectToLoginPage'
        redirectToProvider: 'azureActiveDirectory'
      }
      platform: {
        enabled: true
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            clientId: appRegistrationClientId
            clientSecretSettingName: 'WEBAPP_SSR_ENTRA_CLIENT_SECRET'
            openIdIssuer: 'https://sts.windows.net/${subscription().tenantId}/v2.0'
          }
        }
      }
      login: {
        tokenStore: {
          enabled: false
        }
      }
    }
  }
}

module appInsightsDeployment './appinsights.bicep' = {
  name: 'appInsightsDeployment-webapp-ssr'
  params: {
    name: name
    location: location
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: name
}

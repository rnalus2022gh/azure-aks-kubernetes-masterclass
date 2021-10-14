#r "System.Configuration"
#r "System.Security"

using System;
using System.Configuration;
using Microsoft.Azure.Management.AppService.Fluent;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;
using Microsoft.Azure.Management.ResourceManager.Fluent;

public static void Run(TimerInfo myTimer, TraceWriter log)
{
    log.Info($"VM Shutdown function executed at : {DateTime.Now}");
    var sp = new ServicePrincipalLoginInformation();
    sp.ClientId = ConfigurationManager.AppSettings["SERVICE_PRINCIPAL"];
    sp.ClientSecret = ConfigurationManager.AppSettings["SERVICE_PRINCIPAL_SECRET"];
    var tenantId = ConfigurationManager.AppSettings["TENANT_ID"];
    var resourceGroupName = "MyVmDemo";
    var virtualMachineName = "ExampleVm";
    
    var creds = new AzureCredentials(sp, tenantId, AzureEnvironment.AzureGlobalCloud);
    IAzure azure = Azure.Authenticate(creds).WithDefaultSubscription();
    
    var vm = azure.VirtualMachines.GetByResourceGroup(resourceGroupName,virtualMachineName);
    log.Info($"{vm.Name} is {vm.PowerState}");
    
    if (vm.PowerState.Value != "PowerState/deallocated")
    {
        log.Info("Shutting it down:");
        vm.Deallocate();
        log.Info("Done");
    }
}

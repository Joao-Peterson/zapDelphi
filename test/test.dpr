program test;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.TestRunner,
  DUnitX.TestResult,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.XML.NUnit,
  Uzap in '..\src\Uzap.pas',
  Uzap.Types in '..\src\Uzap.Types.pas',
  UphoneNum in '..\modules\phonenum\src\UphoneNum.pas',
  Utests in 'Utests.pas',
  Uzap.Webhook in '..\src\Uzap.Webhook.pas';

var
    runner : ITestRunner;
    results : IRunResults;
    logger : ITestLogger;
    nunitLogger : ITestLogger;

begin
	try	
		ReportMemoryLeaksOnShutdown := True;
	
		//Create the runner
		runner := TDUnitX.CreateRunner;
		runner.UseRTTI := True;

		//tell the runner how we will log things
		if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
		begin
			logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
			runner.AddLogger(logger);
		end;

		nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
		runner.AddLogger(nunitLogger);

		//Run tests
		results := runner.Execute;

		System.Write('Done.. press <Enter> key to quit.');
		System.Readln;
	except
		on E: Exception do Writeln(E.ClassName, ': ', E.Message);
	end;
end.

package.path = package.path .. ";../?.lua"

require("bloom")

local Person = bloom.MetaClass:makeClass("Person", {bloom.Object},
	{
		__init__ =
			function(self, firstname, lastname, gender)
				self.firstname = firstname
				self.lastname = lastname
				self.gender = gender
			end,
		
		getFirstname =
			function(self)
				return self.firstname
			end
	})

local Company = bloom.MetaClass:makeClass("Company", {bloom.Object},
	{
		__init__ =
			function(self, name)
				self.name = name
				self.employeeCount = 0
				self.employees = {}
			end,

		addEmployee = 
			function(self, employee)
				self.employeeCount = self.employeeCount + 1
				self.employees[self.employeeCount] = employee
				return self
			end,
		
		getEmployees =
			function(self)
				return self.employees
			end
	})

local Employee = bloom.MetaClass:makeClass("Person", {Person},
	{
		__init__ =
			function(self, firstname, lastname, gender, role, nickname)
				self.role = role
				self.nick = nickname
			end,
		
		getFirstname =
			function(self)
				local firstname = self:super()() -- get result of class to default base class version of getFirstname()
				if self.nick then
					return firstname .. " \"" .. self.nick .. "\""
				end
				return firstname
			end,
		
		getRole =
			function(self)
				return self.role
			end
	})

local company = Company:instanciate("Microsoft")
local bill = Employee:instanciate("William", "Gates", "Male", "Boss", "Bill")
company:addEmployee(bill)
       :addEmployee(Employee:instanciate("Boby", "Lapointe", "Male", "Developer"))
       :addEmployee(Employee:instanciate("Louise", "Dickinson", "Female", "Architect"))
for id, emp in pairs(company:getEmployees()) do
	print(id, emp:getFirstname() .. " " .. emp:getRole())
end

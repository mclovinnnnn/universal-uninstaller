
Add-Type -AssemblyName System.Windows.Forms
##https://icon-icons.com/de/symbol/Runde-remote-desktop/132781

$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(850, 600)
$form.MinimumSize = $form.Size

$icon = "resources\icon.ico"
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($icon)


$form.Text = "Universal Uninstaller"
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
<#
$iconBase64      = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAABGdBTU
EAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOp
gAABdwnLpRPAAAAkxQTFRFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////KI4PAAAAAMJ0Uk5TAAEPOWqiwdrj9f
7AaTgRSJHD7v359Oni7cSSAiZ9yPf616x2WUEpISBad67Zx3gjJYnfzoJHGgQFG4bR+92I3POqUB
UXVdhxPLr8q0MJCkWv+LkHbeXNVwsMXdNnEpD2lB6ej6boZmzqoRZLp9JlxUxAWELejH9R62Q9bz
cIn7LMH2tftIBEs3BJDc+Dm5OF4Jw6Y3rxjoe+KltgvfBosWIcXNDGVLUk2618YdQiuJqgcjJNT9
U+TpcOE53kBkqwMYTIEUSQAAAAAWJLR0TDimiOQgAAAAlwSFlzAAA7DgAAOw4BzLahgwAABCxJRE
FUWMOdl/9fU1UYx5/tgrs76gbbvQMZtPFlDHQ6hGUDJwxbUNhgE02mzFkpCtMwm7GAxCI1IgKhpn
wJdRSYZdEXw6ysnr+suzXbF3a3e3d+2Dn3Oa/3Z+d5zrnPPQ9A2iaRUnn5W2S0nBA5Lduav227VA
LCm0JZUKhSo5phNXSRhmW4YfGOEqVCGK0tLXtOh/ryisoqA1VtrKmmDLU7d5n0qNu9x6zNikvq9t
ajvsHy/L4XEs3WRmXTfhs50GzOtvjKFrS3HnwxjcMSx0u7WGxrz+SI5OVXOnSHXnXyzXd2udwdhy
necHYfOYqvHevJtELP8RNI93ann/Se9OlOvZ4tSOY33PI307rhOE3O9Dmz8ZwfZ8+p+wfS8IdQ5s
9+WLQerfZgPZ7fpOA9jReo7H+vfWvwIsDbbdif4kX3STQJ4XtV+ktc/06AXE6O5BGdxi+IZ96Nhm
koqHsvcWb4qLtPDA+SEYYeTQjAYTz1vhgewHkFx+JhqMSrH4jjufOwn3z4bFwqcx8TywOMM6a62H
AvtvaI5sHzEV6LLSBgvy6eB7jIBkqjgzJszRbBdDw4b+DHkd67u2MoFx6gVj0Y2YgJpiF+sD8ZlQ
rmwTHp7uK6Avw0butjp7xCeYDPcBpAWmhTxk3DM+SmVygPfluhFGZV5Y0JNmWqQgYeGstVs5CHFU
n5N1WhSqUv40szVheZg3ysTLamKHyOX/BvUghvwRashUwKiikyM8EnMI63QeY2QM4KBkYGtH1zJh
KsQLE0yM9UQ84K8xoWsKgGclYw0oRHQKCCkUaQa6ohZ4WICzTLk84nBCjMskUgYwyQs0JkG7fiAu
SssIhL3FHeyScAQ1+SXsikEMImWCYuKw/vnNYHE171zQrWO+QuUMVt93j4Jia4kHSrSlW4Zyrenp
JQMvKcwk0yk7Bp0YTCpbRpoTyXgad84fhTCVq4X6V70iGU59ZAxbOuYyWaVBVfqb8WzCe1MNkR/b
7uwQpnLnznKo5EB2stqZ82QTz42fuxe2szftMjnves4oPY0FzOLIjm4Vv9d8Zn43ay8lAsv3ZBvf
z/g+J7/MEpju9cR1fCZ3SWdi+L4iU/MvU/JRp6fZqfRfDwS5A9nmToDpGWYa7fphfEGwJqS8o7rO
jHR78CbCxdEsKb8PFvqcaB83h/Q6J1CvB/4wBeebLZPrBOzp0VcN13tgfVj5+km1Fc9ul+r8nGm9
d1dos0/Vz33B84Ge7MhHsWT2B9+E9e70ZvdPjGnvJe+pxPV922v/7OVJYo8kxoH6tKW/YNhFft+G
hZChmbZO1agOgbCvz7kvbZ2ugvWbGRlgdZY8TdqupGBrnSt80VGjdQ80bjPGVYDN2JlL6DIw8FVu
CKrn8ixTeJFN90rPgutFwXWHz/54mUmrt1O1r+s0Wypea7FF/5/y9Z4TxUNDmqzgAAACV0RVh0ZG
F0ZTpjcmVhdGUAMjAyMC0wMi0xMlQxNzoyMzozNCswMDowMFHJSD8AAAAldEVYdGRhdGU6bW9kaW
Z5ADIwMjAtMDItMTJUMTc6MjM6MzQrMDA6MDAglPCDAAAARnRFWHRzb2Z0d2FyZQBJbWFnZU1hZ2
ljayA2LjcuOC05IDIwMTktMDItMDEgUTE2IGh0dHA6Ly93d3cuaW1hZ2VtYWdpY2sub3JnQXviyA
AAABh0RVh0VGh1bWI6OkRvY3VtZW50OjpQYWdlcwAxp/+7LwAAABh0RVh0VGh1bWI6OkltYWdlOj
poZWlnaHQANTEywNBQUQAAABd0RVh0VGh1bWI6OkltYWdlOjpXaWR0aAA1MTIcfAPcAAAAGXRFWH
RUaHVtYjo6TWltZXR5cGUAaW1hZ2UvcG5nP7JWTgAAABd0RVh0VGh1bWI6Ok1UaW1lADE1ODE1Mj
gyMTS8W5itAAAAE3RFWHRUaHVtYjo6U2l6ZQAxNS42S0JC58sE1gAAAFB0RVh0VGh1bWI6OlVSSQ
BmaWxlOi8vLi91cGxvYWRzLzU2L0k4ZHFXamEvMjE1My9yb3VuZF9yZW1vdGVfZGVza3RvcF9pY2
9uXzEzMjc4MS5wbmd3Pbe6AAAAAElFTkSuQmCC'

$iconBytes       = [Convert]::FromBase64String($iconBase64)
# initialize a Memory stream holding the bytes
$stream          = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
$Form.Icon       = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))
#>


$form.ShowDialog()


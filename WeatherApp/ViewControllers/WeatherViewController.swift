//
//  ViewController.swift
//  WeatherApp
//
//  Created by Юрий on 12.05.2025.
//

import UIKit
import CoreLocation
import Kingfisher

enum WeatherState {
    case loading
    case loaded(ForecastResponse)
    case error(Error)
}

class WeatherViewController: UIViewController {
    
    private let weatherAPI = WeatherAPI()
    private var currentWeather: CurrentWeatherResponse?
    private var forecast: ForecastResponse?
    private let locationManager = CLLocationManager()
    
    // MARK: - UI Elements
    
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let cityTempLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let weatherImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let weatherDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let tempRangeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        return label
    }()
    
    private let hourlyCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 50, height: 80)
        layout.minimumInteritemSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(HourlyCell.self, forCellWithReuseIdentifier: "HourlyCell")
        return collectionView
    }()
    
    private let dailyTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(DailyCell.self, forCellReuseIdentifier: "DailyCell")
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "background"))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestLocation()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        let stackView = UIStackView(arrangedSubviews: [
            cityLabel,
            cityTempLabel,
            weatherImage,
            weatherDescriptionLabel,
            tempRangeLabel,
            hourlyCollectionView,
            dailyTableView,
            loadingIndicator
        ])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        dailyTableView.backgroundColor = .clear
        
        hourlyCollectionView.delegate = self
        hourlyCollectionView.dataSource = self
        dailyTableView.delegate = self
        dailyTableView.dataSource = self
        dailyTableView.allowsSelection = false
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            weatherImage.heightAnchor.constraint(equalToConstant: 120),
            hourlyCollectionView.heightAnchor.constraint(equalToConstant: 120),
            dailyTableView.heightAnchor.constraint(equalToConstant: 7 * 44),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Private Methods
    
    private func fetchWeather(lat: Double, lon: Double) {
        loadingIndicator.startAnimating()
        
        let group = DispatchGroup()
        var currentResult: Result<CurrentWeatherResponse, Error>?
        var forecastResult: Result<ForecastResponse, Error>?
        
        group.enter()
        weatherAPI.fetchCurrentWeather(lat: lat, lon: lon) {
            currentResult = $0
            group.leave()
        }
        
        group.enter()
        weatherAPI.fetchForecast(lat: lat, lon: lon) {
            forecastResult = $0
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.loadingIndicator.stopAnimating()
            switch (currentResult, forecastResult) {
            case (.success(let current), .success(let forecast)):
                self?.currentWeather = current
                self?.forecast = forecast
                self?.updateCurrentWeatherUI()
                self?.updateForecastUI()
            case (.failure(let error), _), (_, .failure(let error)):
                self?.showErrorWithRetry(error)
            default:
                break
            }
        }
    }
    
    private func showErrorWithRetry(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось загрузить данные: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        alert.addAction(UIAlertAction(
            title: "Повторить",
            style: .default,
            handler: { [weak self] _ in
                self?.requestLocation()
            }
        ))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    private func updateCurrentWeatherUI() {
        guard let data = currentWeather else { return }
        
        DispatchQueue.main.async {
            self.cityLabel.text = "\(data.location.name)"
            self.cityTempLabel.text =  "\(Int(data.current.tempC))°"
            self.weatherDescriptionLabel.text = data.current.condition.text
            
            if let iconURL = URL(string: "https:\(data.current.condition.icon)") {
                self.weatherImage.kf.setImage(with: iconURL)
            }
        }
    }
    
    private func updateForecastUI() {
        guard let forecast = forecast,
              !forecast.forecast.forecastday.isEmpty else { return }
        
        print("Получено дней прогноза:", forecast.forecast.forecastday.count)
        
        DispatchQueue.main.async {
            self.hourlyCollectionView.reloadData()
            self.dailyTableView.reloadData()
            
            if let day = forecast.forecast.forecastday.first?.day {
                self.tempRangeLabel.text = "Макс.: \(Int(day.maxtempC))°, мин.: \(Int(day.mintempC))°"
            }
        }
    }
    
    private func requestLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // Проверяем текущий статус (на случай, если разрешение уже дано)
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    private func filterHoursForCurrentAndNextDay(hours: [Hour]) -> [Hour] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        // Получаем текущую дату и время
        let now = Date()
        let calendar = Calendar.current
        
        // Фильтруем часы: оставшиеся сегодня + все завтра
        var filteredHours = [Hour]()
        var foundCurrentHour = false
        
        for hour in hours {
            guard let hourDate = dateFormatter.date(from: hour.time) else { continue }
            
            if calendar.isDate(hourDate, inSameDayAs: now) {
                // Часы текущего дня (только те, что еще не прошли)
                if hourDate >= now {
                    filteredHours.append(hour)
                    foundCurrentHour = true
                }
            } else if foundCurrentHour {
                // После того как нашли текущий час, добавляем все последующие
                filteredHours.append(hour)
            }
        }
        
        return filteredHours
    }
}


// MARK: - CollectionView (почасовой прогноз)
extension WeatherViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let forecastDays = forecast?.forecast.forecastday,
              forecastDays.count >= 2 else {
            return 0
        }
        
        // Объединяем часы текущего и следующего дня
        let todayHours = forecastDays[0].hour
        let tomorrowHours = forecastDays[1].hour
        
        let filteredTodayHours = filterHoursForCurrentAndNextDay(hours: todayHours)
        let allHours = filteredTodayHours + tomorrowHours
        
        return min(allHours.count, 48) // Ограничиваем 48 часами (2 дня)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HourlyCell", for: indexPath) as! HourlyCell
        
        guard let forecastDays = forecast?.forecast.forecastday,
              forecastDays.count >= 2 else {
            return cell
        }
        
        let todayHours = forecastDays[0].hour
        let tomorrowHours = forecastDays[1].hour
        
        let filteredTodayHours = filterHoursForCurrentAndNextDay(hours: todayHours)
        let allHours = filteredTodayHours + tomorrowHours
        
        guard indexPath.row < allHours.count else {
            return cell
        }
        
        let hourData = allHours[indexPath.row]
        let time = String(hourData.time.suffix(5)) // Формат "HH:mm"
        let iconURL = hourData.condition.iconURL
        
        cell.configure(hour: time, temp: "\(Int(hourData.tempC))°", iconURL: iconURL)
        
        return cell
    }
}

// MARK: - TableView (прогноз на 7 дней)
extension WeatherViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(forecast?.forecast.forecastday.count ?? 0, 7)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DailyCell", for: indexPath) as! DailyCell
        
        if let dayData = forecast?.forecast.forecastday[indexPath.row] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let date = dateFormatter.date(from: dayData.date) else {
                return cell
            }
            
            dateFormatter.locale = Locale(identifier: "ru_RU")
            dateFormatter.dateFormat = "E" // Короткое название дня недели
            
            let dayName = dateFormatter.string(from: date)
            let text = "\(dayName):  \(Int(dayData.day.mintempC))° / \(Int(dayData.day.maxtempC))°"
            let iconURL = dayData.day.condition.iconURL
            cell.configure(dayText: text, iconURL: iconURL)        }
        
        return cell
    }
}

// MARK: - Location Manager

extension WeatherViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fetchWeather(lat: 55.7558, lon: 37.6173) // Координаты Москвы
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            fetchWeather(lat: 55.7558, lon: 37.6173) // Москва при отказе
        default:
            break
        }
    }
}
